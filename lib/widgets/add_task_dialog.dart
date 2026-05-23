import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../models/repeating_task.dart';

class AddTaskDialog extends StatefulWidget {
  final String apiKey;
  final Function(String title, String prompt, List<int> baseDays, bool rescheduleOnDiffDay, int intervalDaysIfDiff) onTaskAdded;

  const AddTaskDialog({
    super.key,
    required this.apiKey,
    required this.onTaskAdded,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _promptController = TextEditingController();
  final _aiService = AiService();
  
  bool _isLoading = false;
  ParsedTaskRule? _parsedRule;
  String _errorText = '';

  // Input editing controllers if user wants to tweak before saving
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void dispose() {
    _promptController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _translatePrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) {
      setState(() {
        _errorText = 'Please describe your repeating task.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = '';
      _parsedRule = null;
    });

    try {
      final parsed = await _aiService.translatePrompt(prompt, widget.apiKey);
      setState(() {
        _parsedRule = parsed;
        _titleController.text = parsed.title;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to parse prompt. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Title Header ---
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.psychology_outlined, color: AppTheme.primaryTeal, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'AI Task Creator',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Main Step 1: Input Promp ---
              if (_parsedRule == null) ...[
                Text(
                  'Describe your task and repeating rules in natural language:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promptController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Put on a new patch on Thursday and Sunday. If done on a different day, reschedule for that day and wait 3 days.',
                  ),
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
                if (_errorText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorText,
                    style: const TextStyle(color: AppTheme.accentNeonOrange, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 20),
                
                // Loading / Submit row
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _translatePrompt,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Translate with AI',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ]
              // --- Step 2: Confirm Preview ---
              else ...[
                Text(
                  'Review the parsed schedule details:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                ),
                const SizedBox(height: 16),
                
                // Title Field
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                  ),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // Rule breakdown container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Base Days
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.event_note, size: 18, color: AppTheme.primaryTeal),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Base Repeating Days:', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  _parsedRule!.baseDays.map((d) => RepeatingTask.getWeekdayName(d)).join(', '),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Reschedule Rule
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sync_alt_rounded, size: 18, color: AppTheme.primaryMagenta),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Dynamic Reschedule:', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  _parsedRule!.rescheduleOnDiffDay
                                      ? 'Yes, reschedule if done on non-base days'
                                      : 'No, strictly lock to base days',
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (_parsedRule!.rescheduleOnDiffDay) ...[
                        const SizedBox(height: 14),
                        // Delay interval
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.update_rounded, size: 18, color: AppTheme.accentNeonPurple),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Reschedule Delay Interval:', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_parsedRule!.intervalDaysIfDiff} days after completion',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Button row
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() {
                            _parsedRule = null;
                          });
                        },
                        child: Text('Back', style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          final finalTitle = _titleController.text.trim().isNotEmpty 
                              ? _titleController.text.trim() 
                              : _parsedRule!.title;
                          widget.onTaskAdded(
                            finalTitle,
                            _promptController.text.trim(),
                            _parsedRule!.baseDays,
                            _parsedRule!.rescheduleOnDiffDay,
                            _parsedRule!.intervalDaysIfDiff,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            height: 52,
                            alignment: Alignment.center,
                            child: const Text(
                              'Create Task',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
