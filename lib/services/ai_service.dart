import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/repeating_task.dart';

class ParsedTaskRule {
  final String title;
  final String description;
  final List<int> baseDays;
  final bool rescheduleOnDiffDay;
  final int intervalDaysIfDiff;

  ParsedTaskRule({
    required this.title,
    required this.description,
    required this.baseDays,
    required this.rescheduleOnDiffDay,
    required this.intervalDaysIfDiff,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'baseDays': baseDays,
      'rescheduleOnDiffDay': rescheduleOnDiffDay,
      'intervalDaysIfDiff': intervalDaysIfDiff,
    };
  }
}

class AiService {
  static const String _systemPrompt = '''
You are a precise task scheduling translator. Your job is to parse natural language rules for repeating tasks and output a single JSON object.
Do NOT include markdown formatting (like ```json or ```) or any other text in your response. Output ONLY the raw JSON string.

JSON Structure:
{
  "title": "A short, concise title for the task (e.g. 'Put on a new patch')",
  "description": "A short description of the scheduling rule",
  "baseDays": [4, 7], // List of weekday integers (Monday = 1, Tuesday = 2, Wednesday = 3, Thursday = 4, Friday = 5, Saturday = 6, Sunday = 7)
  "rescheduleOnDiffDay": true, // Whether the task reschedules itself if completed on a different day
  "intervalDaysIfDiff": 3 // The number of days to wait after completing a task on a non-base day
}

Examples:
Prompt: "create a task to put on a new patch on Thursday and Sunday repeating weekly. if done on a different day, reschedule for that day and then make the next due date 3 days later until the next due date is Thursday or Sunday"
JSON:
{
  "title": "Put on a new patch",
  "description": "Repeat Thursday & Sunday. If done on a different day, wait 3 days.",
  "baseDays": [4, 7],
  "rescheduleOnDiffDay": true,
  "intervalDaysIfDiff": 3
}

Prompt: "Go to the gym on Monday and Wednesday. If done on a different day, reschedule for that day and make the next due date 2 days later."
JSON:
{
  "title": "Go to the gym",
  "description": "Repeat Monday & Wednesday. If done on a different day, wait 2 days.",
  "baseDays": [1, 3],
  "rescheduleOnDiffDay": true,
  "intervalDaysIfDiff": 2
}
''';

  // Translate natural language prompt to scheduling rules
  Future<ParsedTaskRule> translatePrompt(String prompt, String apiKey) async {
    if (apiKey.trim().isNotEmpty) {
      try {
        final model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.system(_systemPrompt),
        );
        
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text;
        
        if (text != null && text.trim().isNotEmpty) {
          // Strip any markdown fences just in case
          String cleaned = text.trim();
          if (cleaned.startsWith('```')) {
            cleaned = cleaned.replaceAll(RegExp(r'^```(json)?|```$'), '').trim();
          }
          
          final Map<String, dynamic> data = jsonDecode(cleaned);
          return ParsedTaskRule(
            title: data['title'] ?? 'Repeating Task',
            description: data['description'] ?? prompt,
            baseDays: List<int>.from(data['baseDays'] ?? [1]),
            rescheduleOnDiffDay: data['rescheduleOnDiffDay'] ?? true,
            intervalDaysIfDiff: data['intervalDaysIfDiff'] ?? 3,
          );
        }
      } catch (e) {
        // Fallback to local parser on error
      }
    }
    
    // Fallback to local heuristic parser
    return parseLocally(prompt);
  }

  // Purely offline heuristic/regex-based parser for quick, robust processing
  ParsedTaskRule parseLocally(String prompt) {
    final lower = prompt.toLowerCase();
    
    // 1. Detect Weekdays
    final List<int> baseDays = [];
    if (lower.contains('monday')) baseDays.add(1);
    if (lower.contains('tuesday')) baseDays.add(2);
    if (lower.contains('wednesday')) baseDays.add(3);
    if (lower.contains('thursday')) baseDays.add(4);
    if (lower.contains('friday')) baseDays.add(5);
    if (lower.contains('saturday')) baseDays.add(6);
    if (lower.contains('sunday')) baseDays.add(7);
    
    // Default to Monday and Thursday if none detected
    if (baseDays.isEmpty) {
      baseDays.addAll([1, 4]); 
    }
    
    // Sort chronological (Monday to Sunday)
    baseDays.sort();

    // 2. Extract Title
    String title = 'Repeating Task';
    
    // Look for patterns like "create a task to [action]" or "task to [action]"
    final taskToRegex = RegExp(r'(?:create a task to|task to|create a task for|task for)\s+([^.]+)', caseSensitive: false);
    final match = taskToRegex.firstMatch(prompt);
    if (match != null && match.groupCount >= 1) {
      String rawTitle = match.group(1)!.trim();
      
      // Clean up day indicators from the title if they've leaked in
      rawTitle = rawTitle
          .replaceAll(RegExp(r'\b(?:on|every)?\s*(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?:\s*and\s*(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday))?\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\brepeating\s+weekly\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'\s{2,}', caseSensitive: false), ' ')
          .trim();
          
      if (rawTitle.isNotEmpty) {
        // Capitalize first letter
        title = rawTitle[0].toUpperCase() + rawTitle.substring(1);
      }
    } else {
      // Fallback: extract the first 4-5 words or use a default
      final words = prompt.split(' ');
      if (words.length > 1) {
        title = words.take(5).join(' ');
      }
    }

    // 3. Reschedule Rules
    final reschedule = lower.contains('different day') || lower.contains('reschedule') || lower.contains('if done');
    
    // 4. Interval Days Later
    int interval = 3;
    final intervalMatch = RegExp(r'(\d+)\s*days?\s*later', caseSensitive: false).firstMatch(lower);
    if (intervalMatch != null && intervalMatch.groupCount >= 1) {
      interval = int.tryParse(intervalMatch.group(1)!) ?? 3;
    }

    // 5. Build Description
    final daysStr = baseDays.map((d) => RepeatingTask.getWeekdayName(d)).join(' & ');
    final description = 'Repeat $daysStr. If done on a different day, wait $interval days.';

    return ParsedTaskRule(
      title: title,
      description: description,
      baseDays: baseDays,
      rescheduleOnDiffDay: reschedule,
      intervalDaysIfDiff: interval,
    );
  }
}
