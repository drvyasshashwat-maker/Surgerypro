import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/processing_service.dart';
import '../theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<Book> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await DatabaseService.getBooks();
    if (mounted) setState(() { _books = books; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const UploadScreen())).then((_) => _load()),
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
        : _books.isEmpty
          ? _buildEmpty()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppTheme.accent,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _books.length,
                itemBuilder: (_, i) => _BookCard(book: _books[i], onRefresh: _load),
              ),
            ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.library_books_outlined, size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        const Text('No books uploaded yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.upload_file_rounded),
          label: const Text('Upload Book'),
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const UploadScreen())).then((_) => _load()),
        ),
      ],
    ),
  );
}

class _BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onRefresh;
  const _BookCard({required this.book, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    book.fileType == 'pdf' ? Icons.picture_as_pdf_rounded
                      : book.fileType == 'image' ? Icons.image_rounded
                      : Icons.book_rounded,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: const TextStyle(
                        color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 15,
                      )),
                      const SizedBox(height: 2),
                      Row(children: [
                        _Tag(book.category, AppTheme.categoryColor(book.category)),
                        const SizedBox(width: 6),
                        _Tag(book.fileType.toUpperCase(), AppTheme.textSecondary),
                      ]),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: AppTheme.cardBg,
                  onSelected: (v) async {
                    if (v == 'delete') {
                      await DatabaseService.deleteBook(book.id);
                      onRefresh();
                    } else if (v == 'reprocess') {
                      ProcessingService.processBook(book, book.category);
                      onRefresh();
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'reprocess', child: Text('Reprocess', style: TextStyle(color: AppTheme.textPrimary))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.error))),
                  ],
                ),
              ],
            ),

            if (book.isProcessing) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: LinearProgressIndicator(
                  value: book.totalPages > 0 ? book.processedPages / book.totalPages : null,
                  color: AppTheme.accent,
                  backgroundColor: AppTheme.cardBg,
                )),
                const SizedBox(width: 8),
                Text(book.totalPages > 0 ? '${book.processedPages}/${book.totalPages}' : 'Processing...',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ]),
            ],

            if (book.isProcessed && book.summary != null) ...[
              const SizedBox(height: 10),
              Text(book.summary!.substring(0, book.summary!.length.clamp(0, 200)) + '...',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
            ],

            if (!book.isProcessing && !book.isProcessed) ...[
              const SizedBox(height: 10),
              Text('Not yet processed', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String _category = 'MRCS';
  bool _uploading = false;
  String? _status;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'epub', 'txt', 'jpg', 'jpeg', 'png'],
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.path == null) return;

    setState(() { _uploading = true; _status = 'Uploading...'; });

    try {
      final book = Book()
        ..title = file.name.replaceAll(RegExp(r'\.[^.]+$'), '')
        ..filePath = file.path!
        ..fileType = ProcessingService.getFileType(file.path!)
        ..uploadedAt = DateTime.now()
        ..category = _category;

      await DatabaseService.saveBook(book);
      setState(() => _status = 'Processing in background...');

      // Start processing without awaiting
      ProcessingService.processBook(book, _category).then((_) {
        if (mounted) setState(() => _status = 'Done! Content generated.');
      }).catchError((e) {
        if (mounted) setState(() => _status = 'Error: $e');
      });

      setState(() => _uploading = false);
    } catch (e) {
      setState(() { _uploading = false; _status = 'Upload failed: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Upload Material')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Category', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: ['MRCS', 'FRCS', 'NHS', 'General'].map((c) => ChoiceChip(
                label: Text(c),
                selected: _category == c,
                onSelected: (_) => setState(() => _category = c),
                selectedColor: AppTheme.categoryColor(c).withOpacity(0.2),
                labelStyle: TextStyle(
                  color: _category == c ? AppTheme.categoryColor(c) : AppTheme.textSecondary,
                ),
              )).toList(),
            ),
            const SizedBox(height: 32),

            GestureDetector(
              onTap: _uploading ? null : _pickAndUpload,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _uploading ? AppTheme.accent : const Color(0xFF1E3A5F),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _uploading ? Icons.hourglass_empty_rounded : Icons.upload_file_rounded,
                      size: 48,
                      color: _uploading ? AppTheme.accent : AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _uploading ? 'Processing...' : 'Tap to upload',
                      style: TextStyle(
                        color: _uploading ? AppTheme.accent : AppTheme.textPrimary,
                        fontSize: 16, fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('PDF · EPUB · Images · Text', style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13,
                    )),
                  ],
                ),
              ),
            ),

            if (_status != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_rounded, color: AppTheme.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_status!, style: const TextStyle(color: AppTheme.success))),
                ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
