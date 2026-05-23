import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'widgets/magic_cursor.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized first
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Storage & Notification Services
  final storageService = await StorageService.init();
  final notificationService = await NotificationService.init();

  runApp(
    RepeatingTodoApp(
      storageService: storageService,
      notificationService: notificationService,
    ),
  );
}

class RepeatingTodoApp extends StatefulWidget {
  final StorageService storageService;
  final NotificationService notificationService;

  const RepeatingTodoApp({
    super.key,
    required this.storageService,
    required this.notificationService,
  });

  @override
  State<RepeatingTodoApp> createState() => _RepeatingTodoAppState();
}

class _RepeatingTodoAppState extends State<RepeatingTodoApp> {
  @override
  Widget build(BuildContext context) {
    // Read dynamic settings on rebuild
    final magicCursorEnabled = widget.storageService.getMagicCursorEnabled();
    final magicCursorIntensity = widget.storageService.getMagicCursorIntensity();

    return MaterialApp(
      title: 'Repeating To-Do Tasks',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Hardcoded dark mode for premium obsidian looks
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Embed the beautiful touch-tracking Magic Cursor trail across all pages
        return MagicCursor(
          enabled: magicCursorEnabled,
          intensity: magicCursorIntensity,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: HomeScreen(
        storageService: widget.storageService,
        notificationService: widget.notificationService,
      ),
    );
  }
}
