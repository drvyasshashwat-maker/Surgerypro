import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/gemini_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings? _settings;
  final _apiKeyController = TextEditingController();
  bool _apiKeyVisible = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await DatabaseService.getSettings();
    setState(() {
      _settings = s;
      _apiKeyController.text = s.geminiApiKey;
    });
  }

  Future<void> _save() async {
    if (_settings == null) return;
    setState(() => _saving = true);
    _settings!.geminiApiKey = _apiKeyController.text.trim();
    await DatabaseService.saveSettings(_settings!);
    await GeminiService.updateApiKey(_settings!.geminiApiKey);
    setState(() => _saving = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved'), backgroundColor: AppTheme.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_settings == null) return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
    );

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // API Key
            _SectionHeader('Gemini AI'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('API Key', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: !_apiKeyVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter Gemini API key...',
                        suffixIcon: IconButton(
                          icon: Icon(_apiKeyVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppTheme.textSecondary),
                          onPressed: () => setState(() => _apiKeyVisible = !_apiKeyVisible),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Get your free API key at makersuite.google.com',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Study Goals
            _SectionHeader('Study Goals'),
            Card(
              child: Column(
                children: [
                  _SliderTile(
                    label: 'Daily MCQ Target',
                    value: _settings!.dailyMcqTarget.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    display: '${_settings!.dailyMcqTarget} questions',
                    onChanged: (v) => setState(() => _settings!.dailyMcqTarget = v.round()),
                  ),
                  const Divider(color: Color(0xFF1E3A5F), height: 1),
                  _SliderTile(
                    label: 'Daily Study Time',
                    value: _settings!.dailyStudyMinutes.toDouble(),
                    min: 15,
                    max: 240,
                    divisions: 15,
                    display: '${_settings!.dailyStudyMinutes} mins',
                    onChanged: (v) => setState(() => _settings!.dailyStudyMinutes = v.round()),
                  ),
                  const Divider(color: Color(0xFF1E3A5F), height: 1),
                  _SliderTile(
                    label: 'Exam Timer (per question)',
                    value: _settings!.examTimerSeconds.toDouble(),
                    min: 30,
                    max: 180,
                    divisions: 15,
                    display: '${_settings!.examTimerSeconds}s',
                    onChanged: (v) => setState(() => _settings!.examTimerSeconds = v.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Toggles
            _SectionHeader('Preferences'),
            Card(
              child: Column(
                children: [
                  _SwitchTile(
                    label: 'Show explanation after answer',
                    subtitle: 'In practice and timed modes',
                    value: _settings!.showExplanationAfterAnswer,
                    onChanged: (v) => setState(() => _settings!.showExplanationAfterAnswer = v),
                  ),
                  const Divider(color: Color(0xFF1E3A5F), height: 1),
                  _SwitchTile(
                    label: 'Auto-generate from uploaded books',
                    subtitle: 'Process books automatically',
                    value: _settings!.autoGenerateFromBooks,
                    onChanged: (v) => setState(() => _settings!.autoGenerateFromBooks = v),
                  ),
                  const Divider(color: Color(0xFF1E3A5F), height: 1),
                  _SwitchTile(
                    label: 'Background processing',
                    subtitle: 'Continue processing when app is closed',
                    value: _settings!.backgroundProcessing,
                    onChanged: (v) => setState(() => _settings!.backgroundProcessing = v),
                  ),
                  const Divider(color: Color(0xFF1E3A5F), height: 1),
                  _SwitchTile(
                    label: 'Daily study reminder',
                    subtitle: 'Get notified to study daily',
                    value: _settings!.dailyReminder,
                    onChanged: (v) => setState(() => _settings!.dailyReminder = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Default category
            _SectionHeader('Default Category'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  children: AppTheme.categories.map((c) => ChoiceChip(
                    label: Text(c),
                    selected: _settings!.defaultCategory == c,
                    onSelected: (_) => setState(() => _settings!.defaultCategory = c),
                    selectedColor: AppTheme.categoryColor(c == 'All' ? 'General' : c).withOpacity(0.2),
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: const TextStyle(
      color: AppTheme.textSecondary, fontSize: 13,
      fontWeight: FontWeight.w700, letterSpacing: 1,
    )),
  );
}

class _SliderTile extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String display;
  final ValueChanged<double> onChanged;

  const _SliderTile({required this.label, required this.value, required this.min,
    required this.max, required this.divisions, required this.display, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
          Text(display, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
        ]),
        Slider(value: value, min: min, max: max, divisions: divisions,
          activeColor: AppTheme.accent, onChanged: onChanged),
      ],
    ),
  );
}

class _SwitchTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({required this.label, required this.subtitle,
    required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(label, style: const TextStyle(color: AppTheme.textPrimary)),
    subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
    value: value,
    onChanged: onChanged,
    activeColor: AppTheme.accent,
  );
}
