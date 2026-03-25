import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../theme.dart';

class ImagesScreen extends StatefulWidget {
  const ImagesScreen({super.key});

  @override
  State<ImagesScreen> createState() => _ImagesScreenState();
}

class _ImagesScreenState extends State<ImagesScreen> {
  List<ClinicalImage> _images = [];
  String _category = 'All';
  String _type = 'All';
  bool _loading = true;

  final _types = ['All', 'Clinical', 'Radiology', 'Sketch', 'Diagram'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final images = await DatabaseService.getImages(category: _category);
    if (mounted) setState(() { _images = images; _loading = false; });
  }

  List<ClinicalImage> get _filtered => _type == 'All'
    ? _images
    : _images.where((i) => i.type == _type).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Clinical Images')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: AppTheme.categories.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) { setState(() => _category = c); _load(); },
                      selectedColor: AppTheme.categoryColor(c == 'All' ? 'General' : c).withOpacity(0.2),
                    ),
                  )).toList()),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: _types.map((t) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: _type == t,
                      onSelected: (_) => setState(() => _type = t),
                    ),
                  )).toList()),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
              : _filtered.isEmpty
                ? _buildEmpty()
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _ImageCard(image: _filtered[i]),
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
        const Icon(Icons.image_outlined, size: 64, color: AppTheme.textSecondary),
        const SizedBox(height: 16),
        const Text('No images yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 18)),
        const SizedBox(height: 8),
        const Text('Upload books with images to get started', style: TextStyle(color: AppTheme.textSecondary)),
      ],
    ),
  );
}

class _ImageCard extends StatelessWidget {
  final ClinicalImage image;
  const _ImageCard({required this.image});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => _ImageDetailScreen(image: image))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppTheme.primary,
                child: const Icon(Icons.image_rounded, size: 48, color: AppTheme.textSecondary),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(image.title, style: const TextStyle(
                    color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(image.type, style: const TextStyle(
                        color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w600,
                      )),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageDetailScreen extends StatelessWidget {
  final ClinicalImage image;
  const _ImageDetailScreen({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: Text(image.type)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 300,
              color: AppTheme.primary,
              child: const Icon(Icons.image_rounded, size: 80, color: AppTheme.textSecondary),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(image.type, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.categoryColor(image.category).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(image.category, style: TextStyle(
                        color: AppTheme.categoryColor(image.category), fontWeight: FontWeight.w700,
                      )),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(image.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Text(image.description, style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 15, height: 1.7,
                  )),
                  if (image.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, children: image.tags.map((t) =>
                      Chip(label: Text(t, style: const TextStyle(fontSize: 12)))).toList()),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
