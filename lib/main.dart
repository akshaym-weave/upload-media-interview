// Candidate note: UI changes are allowed. Preserve the initial five media items
// and the Add media / Restart demo behaviors. See QUESTIONS.md for edit boundaries.

import 'package:flutter/material.dart';

import 'media_item.dart';
import 'upload_manager.dart';
import 'upload_service.dart';

void main() => runApp(const MediaUploadApp());

class MediaUploadApp extends StatelessWidget {
  const MediaUploadApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
        home: const UploadQueueScreen(),
      );
}

class UploadQueueScreen extends StatefulWidget {
  const UploadQueueScreen({super.key});

  @override
  State<UploadQueueScreen> createState() => _UploadQueueScreenState();
}

class _UploadQueueScreenState extends State<UploadQueueScreen> {
  late final UploadManager manager;
  var addedItems = 0;

  @override
  void initState() {
    super.initState();
    manager = UploadManager(const DemoUploadService());
    manager.addAll(_initialMedia());
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: manager,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Media uploads'),
            actions: [
              IconButton(
                key: const Key('restart-demo'),
                tooltip: 'Restart demo',
                onPressed: _restartDemo,
                icon: const Icon(Icons.restart_alt),
              ),
              IconButton(
                key: const Key('add-media'),
                tooltip: 'Add simulated media',
                onPressed: _addMedia,
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${manager.activeCount}/${manager.maxConcurrent} uploading',
                      key: const Key('active-count'),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      key: const Key('aggregate-progress'),
                      value: manager.aggregateProgress.clamp(0, 1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  key: const Key('upload-list'),
                  itemCount: manager.items.length,
                  itemBuilder: (context, index) =>
                      _UploadRow(item: manager.items[index], manager: manager),
                ),
              ),
            ],
          ),
        ),
      );

  void _restartDemo() {
    addedItems = 0;
    manager.restart(_initialMedia());
  }

  void _addMedia() {
    final index = ++addedItems;
    manager.addAll([
      MediaItem(
        id: 'added-$index',
        name: 'new_photo_$index.jpg',
        type: MediaType.image,
        totalBytes: (index + 2) * 700000,
      ),
    ]);
  }

  // Candidate note: keep this demo data unchanged.
  List<MediaItem> _initialMedia() => const [
        MediaItem(
          id: 'image-1',
          name: 'team_photo.jpg',
          type: MediaType.image,
          totalBytes: 2400000,
        ),
        MediaItem(
          id: 'video-1',
          name: 'product_demo.mp4',
          type: MediaType.video,
          totalBytes: 12000000,
        ),
        MediaItem(
          id: 'image-2',
          name: 'receipt.png',
          type: MediaType.image,
          totalBytes: 800000,
        ),
        MediaItem(
          id: 'video-2',
          name: 'walkthrough.mov',
          type: MediaType.video,
          totalBytes: 18500000,
        ),
        MediaItem(
          id: 'image-3',
          name: 'whiteboard.jpg',
          type: MediaType.image,
          totalBytes: 3100000,
        ),
      ];
}

class _UploadRow extends StatelessWidget {
  const _UploadRow({required this.item, required this.manager});

  final MediaItem item;
  final UploadManager manager;

  @override
  Widget build(BuildContext context) => ListTile(
        key: ValueKey(item.id),
        leading:
            Icon(item.type == MediaType.image ? Icons.image : Icons.videocam),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.error ?? item.status.name),
            LinearProgressIndicator(value: item.progress.clamp(0, 1)),
          ],
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (item.status == UploadStatus.failed)
              IconButton(
                tooltip: 'Retry',
                onPressed: () => manager.retry(item.id),
                icon: const Icon(Icons.refresh),
              ),
            if (item.status != UploadStatus.completed &&
                item.status != UploadStatus.cancelled)
              IconButton(
                tooltip: 'Cancel',
                onPressed: () => manager.cancel(item.id),
                icon: const Icon(Icons.close),
              ),
          ],
        ),
      );
}
