import 'package:flutter_test/flutter_test.dart';
import 'package:repeating_todo_tasks/models/repeating_task.dart';

void main() {
  group('Scheduling Engine Unit Tests', () {
    
    // Helper to format dates for easy verification
    String fmt(DateTime dt) => "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

    test('Verification of base days schedule (Thursday & Sunday)', () {
      // 2026-05-24 is a Sunday (weekday = 7)
      final Sunday = DateTime(2026, 5, 24);
      
      final task = RepeatingTask(
        id: '1',
        title: 'New Patch',
        description: 'Test patch',
        prompt: 'Put on a patch on Thursday and Sunday weekly...',
        baseDays: [4, 7], // Thursday, Sunday
        rescheduleOnDiffDay: true,
        intervalDaysIfDiff: 3,
        currentDueDate: Sunday,
      );

      // Future 4 occurrences should be: Thursday, Sunday, Thursday, Sunday
      final upcoming = task.getUpcomingDates(4);
      
      expect(fmt(upcoming[0]), "2026-05-28"); // Thursday
      expect(fmt(upcoming[1]), "2026-05-31"); // Sunday
      expect(fmt(upcoming[2]), "2026-06-04"); // Thursday
      expect(fmt(upcoming[3]), "2026-06-07"); // Sunday
    });

    test('Overdue auto roll-forward from Sunday to Monday', () {
      final Sunday = DateTime(2026, 5, 24);
      final Monday = DateTime(2026, 5, 25);

      final task = RepeatingTask(
        id: '1',
        title: 'New Patch',
        description: 'Test patch',
        prompt: '...',
        baseDays: [4, 7],
        rescheduleOnDiffDay: true,
        intervalDaysIfDiff: 3,
        currentDueDate: Sunday,
      );

      // Run rollover on Monday. Because Sunday is in past and not marked done, currentDueDate should move to Monday!
      final rolled = task.checkAndRollOver(Monday);
      
      expect(rolled, isTrue);
      expect(fmt(task.currentDueDate), "2026-05-25"); // Now due Monday!

      // If active due date is now Monday, what are the upcoming dates?
      // Since Monday is non-base, it should schedule 3 days later -> Thursday
      final upcoming = task.getUpcomingDates(3);
      expect(fmt(upcoming[0]), "2026-05-28"); // Thursday
      expect(fmt(upcoming[1]), "2026-05-31"); // Sunday
      expect(fmt(upcoming[2]), "2026-06-04"); // Thursday
    });

    test('Overdue roll-forward Monday to Tuesday and subsequent rescheduling shifts', () {
      final Sunday = DateTime(2026, 5, 24);
      final Tuesday = DateTime(2026, 5, 26);

      final task = RepeatingTask(
        id: '1',
        title: 'New Patch',
        description: 'Test patch',
        prompt: '...',
        baseDays: [4, 7],
        rescheduleOnDiffDay: true,
        intervalDaysIfDiff: 3,
        currentDueDate: Sunday,
      );

      // Rollover checked on Tuesday morning
      task.checkAndRollOver(Tuesday);
      expect(fmt(task.currentDueDate), "2026-05-26"); // Now due Tuesday!

      // Since active due date is Tuesday (non-base day), completed on Tuesday:
      // Next is Tuesday + 3 = Friday (2026-05-29)
      // Friday is non-base, so next is Friday + 3 = Monday (2026-06-01)
      // Monday is non-base, so next is Monday + 3 = Thursday (2026-06-04 - base day!)
      // Thursday is base, so next is Sunday (2026-06-07)
      final upcoming = task.getUpcomingDates(4);
      
      expect(fmt(upcoming[0]), "2026-05-29"); // Friday
      expect(fmt(upcoming[1]), "2026-06-01"); // Monday
      expect(fmt(upcoming[2]), "2026-06-04"); // Thursday
      expect(fmt(upcoming[3]), "2026-06-07"); // Sunday
    });

    test('Task completion on non-base Monday shifts schedule to Thursday', () {
      final Sunday = DateTime(2026, 5, 24);
      final Monday = DateTime(2026, 5, 25);

      final task = RepeatingTask(
        id: '1',
        title: 'New Patch',
        description: 'Test patch',
        prompt: '...',
        baseDays: [4, 7],
        rescheduleOnDiffDay: true,
        intervalDaysIfDiff: 3,
        currentDueDate: Sunday,
      );

      // Sunday passes, rolled to Monday. Done on Monday:
      task.checkAndRollOver(Monday);
      final nextDue = task.completeTask(Monday);

      expect(fmt(nextDue), "2026-05-28"); // Next due date is Thursday (base day!)
      expect(fmt(task.lastCompletedDate!), "2026-05-25"); // Completed Monday
      
      // Subsequent ones should be back on track (Sunday, Thursday, Sunday)
      final upcoming = task.getUpcomingDates(3);
      expect(fmt(upcoming[0]), "2026-05-31"); // Sunday
      expect(fmt(upcoming[1]), "2026-06-04"); // Thursday
      expect(fmt(upcoming[2]), "2026-06-07"); // Sunday
    });

    test('Task completion on non-base Tuesday pushes next due date to Friday', () {
      final Sunday = DateTime(2026, 5, 24);
      final Tuesday = DateTime(2026, 5, 26);

      final task = RepeatingTask(
        id: '1',
        title: 'New Patch',
        description: 'Test patch',
        prompt: '...',
        baseDays: [4, 7],
        rescheduleOnDiffDay: true,
        intervalDaysIfDiff: 3,
        currentDueDate: Sunday,
      );

      // Roll to Tuesday and complete on Tuesday:
      task.checkAndRollOver(Tuesday);
      final nextDue = task.completeTask(Tuesday);

      expect(fmt(nextDue), "2026-05-29"); // Next due is Friday!
      
      // Friday passes and we complete on Friday:
      // Friday + 3 = Monday (2026-06-01)
      final nextDue2 = task.completeTask(DateTime(2026, 5, 29));
      expect(fmt(nextDue2), "2026-06-01"); // Next due Monday!

      // Monday completed -> Monday + 3 = Thursday (2026-06-04 - base day!)
      final nextDue3 = task.completeTask(DateTime(2026, 6, 1));
      expect(fmt(nextDue3), "2026-06-04"); // Next due Thursday!
      
      // Thursday completed (base day!) -> next base day is Sunday
      final nextDue4 = task.completeTask(DateTime(2026, 6, 4));
      expect(fmt(nextDue4), "2026-06-07"); // Back to Sunday base day!
    });
  });
}
