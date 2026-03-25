import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../theme.dart';
import 'quiz_screen.dart';
import 'library_screen.dart';
import 'notes_screen.dart';
import 'images_screen.dart';
import 'settings_screen.dart';
import 'upload_screen.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, int> _stats = {};

  final _screens = const [
    _DashboardTab(),
    QuizScreen(),
    LibraryScreen(),
    NotesScreen(),
    ImagesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await DatabaseService.getStats();
    if (mounted) setState(() => _stats = stats);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_rounded), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.library_books_rounded), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.notes_rounded), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.image_rounded), label: 'Images'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, int> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await DatabaseService.getStats();
    if (mounted) setState(() { _stats = stats; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SurgeryPro', style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppTheme.accent, letterSpacing: 1,
                        )),
                        const Text('MRCS · FRCS · NHS', style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13, letterSpacing: 2,
                        )),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_rounded, color: AppTheme.accent),
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ChatScreen())),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_rounded, color: AppTheme.textSecondary),
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Stats Grid
                _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard('MCQ Questions', _stats['mcqs'] ?? 0, Icons.quiz_rounded, AppTheme.accent),
                        _StatCard('Study Notes', _stats['notes'] ?? 0, Icons.notes_rounded, const Color(0xFF7B2FBE)),
                        _StatCard('Clinical Images', _stats['images'] ?? 0, Icons.image_rounded, const Color(0xFF2DC653)),
                        _StatCard('Books Uploaded', _stats['books'] ?? 0, Icons.library_books_rounded, AppTheme.warning),
                      ],
                    ),
                const SizedBox(height: 24),

                // Quick Actions
                Text('Quick Start', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                _QuickActionGrid(),
                const SizedBox(height: 24),

                // Upload Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Upload Book / PDF / Image'),
                    onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UploadScreen())).then((_) => _load()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.accent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category breakdown
                if ((_stats['mcqs'] ?? 0) > 0) ...[
                  const SizedBox(height: 12),
                  Text('Content by Category', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(children: AppTheme.categories.skip(1).map((cat) =>
                    Expanded(child: _CategoryChip(cat))
                  ).toList()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value.toString(), style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w800,
                )),
                Text(label, style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Practice MCQs', Icons.check_circle_rounded, AppTheme.accent, 'Practice'),
      ('Timed Quiz', Icons.timer_rounded, AppTheme.warning, 'Timed'),
      ('Flashcards', Icons.style_rounded, const Color(0xFF7B2FBE), 'Flashcard'),
      ('Exam Mode', Icons.school_rounded, AppTheme.error, 'Exam'),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: actions.map((a) => InkWell(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => QuizScreen(initialMode: a.$4))),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: a.$3.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: a.$3.withOpacity(0.3)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(a.$2, color: a.$3, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Text(a.$1, style: TextStyle(
                color: a.$3, fontWeight: FontWeight.w600, fontSize: 13,
              ))),
            ],
          ),
        ),
      )).toList(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;
  const _CategoryChip(this.category);

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(category);
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(category, style: TextStyle(
        color: color, fontWeight: FontWeight.w700, fontSize: 13,
      ), textAlign: TextAlign.center),
    );
  }
}
