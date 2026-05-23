import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repeating_task.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../widgets/infinite_task_list.dart';
import '../widgets/add_task_dialog.dart';
import '../theme/app_theme.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final NotificationService notificationService;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.notificationService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<RepeatingTask> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    final tasks = await widget.storageService.loadTasks();

    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });

    // Update notifications and home widget data on startup
    _updateSystemServices();
  }

  Future<void> _addTask(
    String title,
    String prompt,
    List<int> baseDays,
    bool rescheduleOnDiffDay,
    int intervalDaysIfDiff,
  ) async {
    final now = DateTime.now();
    // Default initial due date is today if today is a base day, else the next base day
    DateTime initialDue = RepeatingTask.stripTime(now);
    if (!baseDays.contains(initialDue.weekday)) {
      DateTime test = initialDue.add(const Duration(days: 1));
      while (!baseDays.contains(test.weekday)) {
        test = test.add(const Duration(days: 1));
      }
      initialDue = test;
    }

    final newTask = RepeatingTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: 'Repeat ${baseDays.map((d) => RepeatingTask.getWeekdayName(d).substring(0, 3)).join(', ')}',
      prompt: prompt,
      baseDays: baseDays,
      rescheduleOnDiffDay: rescheduleOnDiffDay,
      intervalDaysIfDiff: intervalDaysIfDiff,
      currentDueDate: initialDue,
    );

    setState(() {
      _tasks.add(newTask);
    });

    await widget.storageService.saveTasks(_tasks);
    _updateSystemServices();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created task "${newTask.title}"!'),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _completeTask(RepeatingTask task) async {
    final now = DateTime.now();
    
    setState(() {
      task.completeTask(now);
    });

    await widget.storageService.saveTasks(_tasks);
    _updateSystemServices();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Completed "${task.title}"! Next due: ${task.currentDueDate.month}/${task.currentDueDate.day}'),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _deleteTask(RepeatingTask task) async {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });

    await widget.storageService.saveTasks(_tasks);
    _updateSystemServices();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}".'),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Sync with notifications and shared prefs for Android AppWidget
  Future<void> _updateSystemServices() async {
    final enabled = widget.storageService.getNotificationsEnabled();
    await widget.notificationService.rescheduleAll(_tasks, enabled);

    // Save tasks simple representation to shared preferences so Kotlin Home Widget can read it
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // We filter tasks due today
    final cleanToday = RepeatingTask.stripTime(DateTime.now());
    final todayTasks = _tasks.where((t) => RepeatingTask.stripTime(t.currentDueDate).isAtSameMomentAs(cleanToday)).toList();
    
    final titlesList = todayTasks.map((t) => t.title).toList();
    await prefs.setStringList('widget_today_tasks', titlesList);
  }

  @override
  Widget build(BuildContext context) {
    final apiKey = widget.storageService.getGeminiApiKey();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Premium glowing app bar header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repeating',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 28,
                              height: 1.1,
                              foreground: Paint()
                                ..shader = AppTheme.primaryGradient.createShader(
                                  const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0),
                                ),
                            ),
                      ),
                      Text(
                        'To-Do Tasks',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
                    ],
                  ),
                  
                  // Settings Button with glow outline
                  GestureDetector(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(storageService: widget.storageService),
                        ),
                      );
                      // Refresh theme/preferences on return
                      setState(() {});
                      _updateSystemServices();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: AppTheme.primaryTeal,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- Main Body task list ---
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                    )
                  : RefreshIndicator(
                      color: AppTheme.primaryTeal,
                      backgroundColor: AppTheme.darkCard,
                      onRefresh: _loadTasks,
                      child: InfiniteTaskList(
                        tasks: _tasks,
                        onComplete: _completeTask,
                        onDelete: _deleteTask,
                      ),
                    ),
            ),
          ],
        ),
      ),

      // --- Gorgeous floating AI add button ---
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.mediumImpact();
          showDialog(
            context: context,
            builder: (context) => AddTaskDialog(
              apiKey: apiKey,
              onTaskAdded: _addTask,
            ),
          );
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        label: Ink(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryTeal.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Add AI Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
