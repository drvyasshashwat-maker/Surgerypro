import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Note> _notes = [];
  String _category = 'All';
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notes = await DatabaseService.getNotes(category: _category);
    if (mounted) setState(() { _notes = notes; _loading = false; });
  }

  List<Note> get _filtered => _search.isEmpty
    ? _notes
    : _notes.where((n) =>
        n.title.toLowerCase().contains(_search.toLowerCase()) ||
        n.content.toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Study Notes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    hintText: 'Search notes...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppTheme.categories.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: _category == c,
                        onSelected: (_) { setState(() => _category = c); _load(); },
                        selectedColor: AppTheme.categoryColor(c == 'All' ? 'General' : c).withOpacity(0.2),
                      ),
                    )).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : _filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _NoteCard(note: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.notes_outlined, size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        Text(_search.isNotEmpty ? 'No notes found' : 'No notes yet',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
        const SizedBox(height: 8),
        const Text('Upload books to generate notes', style: TextStyle(color: AppTheme.textSecondary)),
      ],
    ),
  );
}

class _NoteCard extends StatelessWidget {
  final Note note;
  const _NoteCard({required this.note});

  Color get _typeColor {
    switch (note.type) {
      case 'KeyPoints': return AppTheme.accent;
      case 'Clinical': return AppTheme.error;
      case 'Anatomy': return const Color(0xFF7B2FBE);
      default: return AppTheme.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _NoteDetailScreen(note: note))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(note.type, style: TextStyle(
                    color: _typeColor, fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.categoryColor(note.category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(note.category, style: TextStyle(
                    color: AppTheme.categoryColor(note.category), fontSize: 11, fontWeight: FontWeight.w600,
                  )),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textSecondary),
              ]),
              const SizedBox(height: 10),
              Text(note.title, style: const TextStyle(
                color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15,
              )),
              const SizedBox(height: 6),
              Text(
                note.content.substring(0, note.content.length.clamp(0, 150)),
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (note.sourceBookTitle != null) ...[
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.book_outlined, size: 12, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(note.sourceBookTitle!, style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11,
                  )),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteDetailScreen extends StatelessWidget {
  final Note note;
  const _NoteDetailScreen({required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(note.type),
        actions: [
          IconButton(
            icon: Icon(note.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: note.isFavorite ? AppTheme.error : AppTheme.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.categoryColor(note.category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(note.category, style: TextStyle(
                  color: AppTheme.categoryColor(note.category), fontWeight: FontWeight.w700,
                )),
              ),
            ]),
            const SizedBox(height: 16),
            Text(note.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.textPrimary,
            )),
            const SizedBox(height: 20),
            Text(note.content, style: const TextStyle(
              color: AppTheme.textPrimary, fontSize: 15, height: 1.8,
            )),
            if (note.sourceBookTitle != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E3A5F)),
                ),
                child: Row(children: [
                  const Icon(Icons.book_rounded, color: AppTheme.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Text('Source: ${note.sourceBookTitle}',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
