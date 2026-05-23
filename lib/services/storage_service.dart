import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/repeating_task.dart';

class StorageService {
  static const String _apiKeyKey = 'gemini_api_key';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _magicCursorEnabledKey = 'magic_cursor_enabled';
  static const String _magicCursorIntensityKey = 'magic_cursor_intensity';
  
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // --- API Key & Settings ---

  String getGeminiApiKey() {
    return _prefs.getString(_apiKeyKey) ?? '';
  }

  Future<bool> setGeminiApiKey(String key) async {
    return await _prefs.setString(_apiKeyKey, key);
  }

  bool getNotificationsEnabled() {
    return _prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<bool> setNotificationsEnabled(bool enabled) async {
    return await _prefs.setBool(_notificationsEnabledKey, enabled);
  }

  bool getMagicCursorEnabled() {
    return _prefs.getBool(_magicCursorEnabledKey) ?? true;
  }

  Future<bool> setMagicCursorEnabled(bool enabled) async {
    return await _prefs.setBool(_magicCursorEnabledKey, enabled);
  }

  double getMagicCursorIntensity() {
    return _prefs.getDouble(_magicCursorIntensityKey) ?? 0.8;
  }

  Future<bool> setMagicCursorIntensity(double intensity) async {
    return await _prefs.setDouble(_magicCursorIntensityKey, intensity);
  }

  // --- Tasks File Storage ---

  Future<File> _getTasksFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/tasks.json');
  }

  Future<List<RepeatingTask>> loadTasks() async {
    try {
      final file = await _getTasksFile();
      if (!await file.exists()) {
        return [];
      }
      
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      
      final List<RepeatingTask> tasks = jsonList
          .map((json) => RepeatingTask.fromJson(json as Map<String, dynamic>))
          .toList();

      // Automatically run rollover on app start
      bool changed = false;
      final now = DateTime.now();
      for (final task in tasks) {
        if (task.checkAndRollOver(now)) {
          changed = true;
        }
      }

      if (changed) {
        await saveTasks(tasks);
      }

      return tasks;
    } catch (e) {
      // Return empty if reading fails
      return [];
    }
  }

  Future<void> saveTasks(List<RepeatingTask> tasks) async {
    try {
      final file = await _getTasksFile();
      final jsonList = tasks.map((task) => task.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      // Handle file writing exception if necessary
    }
  }
}
