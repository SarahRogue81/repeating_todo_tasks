import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const SettingsScreen({super.key, required this.storageService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiKeyController;
  late bool _notificationsEnabled;
  late bool _magicCursorEnabled;
  late double _magicCursorIntensity;

  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController(text: widget.storageService.getGeminiApiKey());
    _notificationsEnabled = widget.storageService.getNotificationsEnabled();
    _magicCursorEnabled = widget.storageService.getMagicCursorEnabled();
    _magicCursorIntensity = widget.storageService.getMagicCursorIntensity();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    await widget.storageService.setGeminiApiKey(key);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gemini API Key saved successfully!'),
        backgroundColor: AppTheme.darkCard,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings & AI Config',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          physics: const BouncingScrollPhysics(),
          children: [
            // --- Section: AI Configuration ---
            _buildSectionHeader('AI LLM Configuration'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _buildContainerDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'To use advanced dynamic natural-language scheduling, add your Google Gemini API Key. If left empty, the app runs perfectly in high-fidelity local fallback mode.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    decoration: InputDecoration(
                      labelText: 'Gemini API Key',
                      hintText: 'AIzaSy...',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureApiKey ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                          color: Colors.white38,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureApiKey = !_obscureApiKey;
                          });
                        },
                      ),
                    ),
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveApiKey,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        child: const Text(
                          'Save API Key',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- Section: General Settings ---
            _buildSectionHeader('General Preferences'),
            Container(
              decoration: _buildContainerDecoration(),
              child: Column(
                children: [
                  // Midnight Notifications
                  SwitchListTile(
                    title: const Text('Midnight Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('Schedule alarm triggers at 00:00 midnight local time on due dates.', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                    value: _notificationsEnabled,
                    activeThumbColor: AppTheme.primaryTeal,
                    activeTrackColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                    onChanged: (val) async {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _notificationsEnabled = val;
                      });
                      await widget.storageService.setNotificationsEnabled(val);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),
                  
                  Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),

                  // Magic Cursor Touch Trails
                  SwitchListTile(
                    title: const Text('Magic Cursor Effect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    subtitle: Text('Draw trailing particle glows and halos behind pointer inputs.', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
                    value: _magicCursorEnabled,
                    activeThumbColor: AppTheme.primaryTeal,
                    activeTrackColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    inactiveThumbColor: Colors.white38,
                    inactiveTrackColor: Colors.white12,
                    onChanged: (val) async {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _magicCursorEnabled = val;
                      });
                      await widget.storageService.setMagicCursorEnabled(val);
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  ),

                  if (_magicCursorEnabled) ...[
                    Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                    
                    // Magic Cursor Intensity
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cursor Trail Intensity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white70)),
                              Text('${(_magicCursorIntensity * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal)),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.primaryTeal,
                              inactiveTrackColor: Colors.white12,
                              thumbColor: AppTheme.primaryTeal,
                              overlayColor: AppTheme.primaryTeal.withValues(alpha: 0.2),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _magicCursorIntensity,
                              min: 0.1,
                              max: 1.0,
                              onChanged: (val) {
                                setState(() {
                                  _magicCursorIntensity = val;
                                });
                              },
                              onChangeEnd: (val) async {
                                HapticFeedback.selectionClick();
                                await widget.storageService.setMagicCursorIntensity(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white38,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  BoxDecoration _buildContainerDecoration() {
    return BoxDecoration(
      color: AppTheme.darkCard,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
