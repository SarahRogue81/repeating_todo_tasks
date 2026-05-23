import 'package:flutter/material.dart';
import '../models/repeating_task.dart';
import '../theme/app_theme.dart';
import 'task_card.dart';

class TaskOccurrence {
  final RepeatingTask task;
  final DateTime dueDate;

  TaskOccurrence({required this.task, required this.dueDate});
}

class InfiniteTaskList extends StatefulWidget {
  final List<RepeatingTask> tasks;
  final Function(RepeatingTask) onComplete;
  final Function(RepeatingTask) onDelete;

  const InfiniteTaskList({
    super.key,
    required this.tasks,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  State<InfiniteTaskList> createState() => _InfiniteTaskListState();
}

class _InfiniteTaskListState extends State<InfiniteTaskList> {
  final ScrollController _scrollController = ScrollController();
  
  // How many occurrences per task to pre-generate initially
  int _preGenerateCount = 30;
  
  // Compiled chronological occurrence list
  List<TaskOccurrence> _occurrences = [];
  
  // Helper to group by date
  final Map<String, List<TaskOccurrence>> _groupedOccurrences = {};
  final List<String> _sortedDateKeys = [];

  @override
  void initState() {
    super.initState();
    _generateOccurrences();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant InfiniteTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Regenerate if tasks change
    _generateOccurrences();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 400) {
      // Near bottom, load more!
      setState(() {
        _preGenerateCount += 30;
        _generateOccurrences();
      });
    }
  }

  void _generateOccurrences() {
    _occurrences = [];
    _groupedOccurrences.clear();
    _sortedDateKeys.clear();

    if (widget.tasks.isEmpty) return;

    final now = DateTime.now();
    final cleanToday = RepeatingTask.stripTime(now);

    for (final task in widget.tasks) {
      final cleanDue = RepeatingTask.stripTime(task.currentDueDate);
      
      // 1. Add current active/overdue occurrence if it's today or in the future
      // If overdue, it has already been rolled to cleanToday, so it is covered!
      _occurrences.add(TaskOccurrence(task: task, dueDate: cleanDue));

      // 2. Generate future occurrences
      final futureDates = task.getUpcomingDates(_preGenerateCount);
      for (final date in futureDates) {
        _occurrences.add(TaskOccurrence(task: task, dueDate: date));
      }
    }

    // 3. Sort chronologically by due date
    _occurrences.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // 4. Group by date string to render nice section headers
    for (final occurrence in _occurrences) {
      final dateKey = _formatDateKey(occurrence.dueDate, cleanToday);
      if (!_groupedOccurrences.containsKey(dateKey)) {
        _groupedOccurrences[dateKey] = [];
        _sortedDateKeys.add(dateKey);
      }
      _groupedOccurrences[dateKey]!.add(occurrence);
    }
  }

  String _formatDateKey(DateTime date, DateTime today) {
    if (date.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (date.isBefore(today)) {
      return 'Overdue';
    }
    
    // Formatting: Monday, May 25, 2026
    final weekday = RepeatingTask.getWeekdayName(date.weekday);
    final monthStr = _getMonthName(date.month);
    return '$weekday, $monthStr ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1: return 'January';
      case 2: return 'February';
      case 3: return 'March';
      case 4: return 'April';
      case 5: return 'May';
      case 6: return 'June';
      case 7: return 'July';
      case 8: return 'August';
      case 9: return 'September';
      case 10: return 'October';
      case 11: return 'November';
      case 12: return 'December';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Icon(
                Icons.rule_folder_outlined,
                size: 64,
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No repeating tasks yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the AI button below to create one!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white30),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), // Bottom padding for Fab
      itemCount: _sortedDateKeys.length,
      itemBuilder: (context, index) {
        final dateKey = _sortedDateKeys[index];
        final dayTasks = _groupedOccurrences[dateKey]!;

        final isTodayOrOverdue = dateKey == 'Today' || dateKey == 'Overdue';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sticky-Style Section Date Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isTodayOrOverdue ? AppTheme.primaryTeal : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    dateKey,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isTodayOrOverdue ? Colors.white : Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
            
            // --- Occurrences List for this Date ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dayTasks.length,
              itemBuilder: (context, taskIndex) {
                final occurrence = dayTasks[taskIndex];
                final task = occurrence.task;
                final cleanDue = RepeatingTask.stripTime(task.currentDueDate);
                
                // Allow ticking off ONLY the current active due date
                // Future planned dates in the scroll list are previews only
                final isCurrentActiveOccurrence = occurrence.dueDate.isAtSameMomentAs(cleanDue);

                return Stack(
                  children: [
                    TaskCard(
                      task: task,
                      onComplete: () {
                        // Triggers state completion
                        widget.onComplete(task);
                      },
                      onDelete: () {
                        widget.onDelete(task);
                      },
                    ),
                    
                    // Display preview badge if this is a future occurrence preview
                    if (!isCurrentActiveOccurrence)
                      Positioned(
                        right: 16,
                        top: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentNeonPurple.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.accentNeonPurple.withValues(alpha: 0.3)),
                          ),
                          child: const Text(
                            'PREVIEW',
                            style: TextStyle(
                              color: AppTheme.accentNeonPurple,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
