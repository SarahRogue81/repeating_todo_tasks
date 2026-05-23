import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/repeating_task.dart';
import '../theme/app_theme.dart';

class TaskCard extends StatelessWidget {
  final RepeatingTask task;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cleanDue = RepeatingTask.stripTime(task.currentDueDate);
    final cleanToday = RepeatingTask.stripTime(now);

    final isOverdue = cleanDue.isBefore(cleanToday);
    final isDueToday = cleanDue.isAtSameMomentAs(cleanToday);

    // Format current due date string
    String dueText = '';
    if (isDueToday) {
      dueText = 'Today (${RepeatingTask.getWeekdayName(cleanDue.weekday)})';
    } else if (isOverdue) {
      dueText = 'Overdue (${RepeatingTask.getWeekdayName(cleanDue.weekday)})';
    } else {
      dueText = '${cleanDue.month}/${cleanDue.day}/${cleanDue.year} (${RepeatingTask.getWeekdayName(cleanDue.weekday)})';
    }

    // Base days formatted string
    final baseDaysStr = task.baseDays.map((d) => RepeatingTask.getWeekdayName(d).substring(0, 3)).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isOverdue
                  ? AppTheme.accentNeonOrange.withValues(alpha: 0.25)
                  : isDueToday
                      ? AppTheme.primaryTeal.withValues(alpha: 0.25)
                      : Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? AppTheme.accentNeonOrange.withValues(alpha: 0.15)
                          : isDueToday
                              ? AppTheme.primaryTeal.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isOverdue ? Icons.warning_rounded : Icons.schedule_rounded,
                          size: 14,
                          color: isOverdue
                              ? AppTheme.accentNeonOrange
                              : isDueToday
                                  ? AppTheme.primaryTeal
                                  : Colors.white60,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOverdue ? 'Overdue' : 'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOverdue
                                ? AppTheme.accentNeonOrange
                                : isDueToday
                                    ? AppTheme.primaryTeal
                                    : Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Delete Button
                  IconButton(
                    icon: Icon(Icons.delete_outline_rounded, color: Colors.white.withValues(alpha: 0.3), size: 20),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onDelete();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // --- Title ---
              Text(
                task.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),

              // --- Original Prompt Info ---
              Text(
                task.prompt,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // --- Divider ---
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
              const SizedBox(height: 16),

              // --- Bottom Info & Action Row ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dates & details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_rounded, size: 14, color: AppTheme.primaryMagenta),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Due: $dueText',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.loop_rounded, size: 14, color: AppTheme.accentNeonPurple),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Schedule: $baseDaysStr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Beautiful Complete Button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onComplete();
                    },
                    child: Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: 400.ms)
    .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic, duration: 400.ms);
  }
}
