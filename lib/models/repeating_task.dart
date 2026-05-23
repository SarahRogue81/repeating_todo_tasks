
class RepeatingTask {
  final String id;
  final String title;
  final String description;
  final String prompt;
  final List<int> baseDays; // Monday = 1, ..., Sunday = 7
  final bool rescheduleOnDiffDay;
  final int intervalDaysIfDiff;
  
  DateTime currentDueDate;
  DateTime? lastCompletedDate;

  RepeatingTask({
    required this.id,
    required this.title,
    required this.description,
    required this.prompt,
    required this.baseDays,
    required this.rescheduleOnDiffDay,
    required this.intervalDaysIfDiff,
    required this.currentDueDate,
    this.lastCompletedDate,
  });

  // Strip time from DateTime to ensure date-only comparison
  static DateTime stripTime(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  // Convert weekday number to localized name
  static String getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  // Automatic overdue roll-forward
  // If the task is overdue (currentDueDate < today), it rolls to today.
  // Returns true if a rollover occurred.
  bool checkAndRollOver(DateTime today) {
    final cleanToday = stripTime(today);
    final cleanDue = stripTime(currentDueDate);

    if (cleanDue.isBefore(cleanToday)) {
      currentDueDate = cleanToday;
      return true;
    }
    return false;
  }

  // Handles completion of the task on a given completionDate
  // Returns the next due date
  DateTime completeTask(DateTime completionDate) {
    final cleanCompletion = stripTime(completionDate);
    DateTime nextDue;

    if (rescheduleOnDiffDay && !baseDays.contains(cleanCompletion.weekday)) {
      // Completed on a different (non-base) day
      nextDue = cleanCompletion.add(Duration(days: intervalDaysIfDiff));
    } else {
      // Completed on a base day, schedule for the next base day
      nextDue = _getNextBaseDay(cleanCompletion);
    }

    lastCompletedDate = cleanCompletion;
    currentDueDate = stripTime(nextDue);
    return currentDueDate;
  }

  // Finds the next chronologically occurring base day after 'from'
  DateTime _getNextBaseDay(DateTime from) {
    DateTime test = from.add(const Duration(days: 1));
    while (!baseDays.contains(test.weekday)) {
      test = test.add(const Duration(days: 1));
    }
    return test;
  }

  // Generates future occurrences for this task starting from currentDueDate
  List<DateTime> getUpcomingDates(int count) {
    List<DateTime> dates = [];
    DateTime current = stripTime(currentDueDate);

    for (int i = 0; i < count; i++) {
      DateTime next;
      if (rescheduleOnDiffDay && !baseDays.contains(current.weekday)) {
        next = current.add(Duration(days: intervalDaysIfDiff));
      } else {
        next = _getNextBaseDay(current);
      }
      dates.add(next);
      current = next;
    }
    return dates;
  }

  // JSON Serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prompt': prompt,
      'baseDays': baseDays,
      'rescheduleOnDiffDay': rescheduleOnDiffDay,
      'intervalDaysIfDiff': intervalDaysIfDiff,
      'currentDueDate': currentDueDate.toIso8601String(),
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
    };
  }

  factory RepeatingTask.fromJson(Map<String, dynamic> json) {
    return RepeatingTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      prompt: json['prompt'] as String,
      baseDays: List<int>.from(json['baseDays'] as List),
      rescheduleOnDiffDay: json['rescheduleOnDiffDay'] as bool,
      intervalDaysIfDiff: json['intervalDaysIfDiff'] as int,
      currentDueDate: DateTime.parse(json['currentDueDate'] as String),
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.parse(json['lastCompletedDate'] as String)
          : null,
    );
  }
}
