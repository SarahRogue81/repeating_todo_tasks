import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/repeating_task.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static Future<NotificationService> init() async {
    final service = NotificationService();
    await service._initialize();
    return service;
  }

  Future<void> _initialize() async {
    // 1. Initialize Timezone Database
    tz.initializeTimeZones();

    // 2. Android Initialization Settings
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click if needed
      },
    );

    // 3. Request POST_NOTIFICATIONS permission (Android 13+)
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  // Reschedule all notifications for active tasks
  // We schedule midnight (00:00) alerts for the next 10 occurrences of each task.
  Future<void> rescheduleAll(List<RepeatingTask> tasks, bool enabled) async {
    // Cancel all existing scheduled notifications first
    await _localNotifications.cancelAll();

    if (!enabled) return;

    int notificationId = 0;
    final now = DateTime.now();

    for (final task in tasks) {
      // 1. Generate the upcoming due dates (including currentDueDate if it is today or in the future)
      final List<DateTime> upcomingDates = [];
      
      final cleanDue = RepeatingTask.stripTime(task.currentDueDate);
      final cleanToday = RepeatingTask.stripTime(now);

      if (cleanDue.isAtSameMomentAs(cleanToday) || cleanDue.isAfter(cleanToday)) {
        upcomingDates.add(cleanDue);
      }
      
      // Get next 9 occurrences
      upcomingDates.addAll(task.getUpcomingDates(9));

      // 2. Schedule a notification at 00:00 midnight for each upcoming date
      for (final date in upcomingDates) {
        final localLocation = tz.local;
        
        // Schedule exactly at midnight (00:00:00) in the device's local timezone
        final scheduleTime = tz.TZDateTime(
          localLocation,
          date.year,
          date.month,
          date.day,
          0, // Hour
          0, // Minute
          0, // Second
        );

        // Ensure we are only scheduling future alerts
        if (scheduleTime.isAfter(tz.TZDateTime.now(localLocation))) {
          await _localNotifications.zonedSchedule(
            notificationId++,
            task.title,
            "Today's Task: ${task.description}",
            scheduleTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'repeating_tasks_channel',
                'Repeating Tasks Alerts',
                channelDescription: 'Alerts at midnight on due dates for tasks',
                importance: Importance.max,
                priority: Priority.high,
                enableVibration: true,
                styleInformation: BigTextStyleInformation(''),
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }
  }
}
