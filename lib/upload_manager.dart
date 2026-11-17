import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'media_item.dart';
import 'upload_service.dart';

class UploadManager extends ChangeNotifier {
  UploadManager(this.service, {this.maxConcurrent = 2});

  final UploadService service;
  final int maxConcurrent;
  final Map<String, MediaItem> _items = {};
  final Queue<String> _queue = Queue<String>();
  final Map<String, StreamSubscription<UploadEvent>> _subscriptions = {};

  List<MediaItem> get items => List.unmodifiable(_items.values);

  int get activeCount => _items.values
      .where((item) => item.status == UploadStatus.uploading)
      .length;

  double get aggregateProgress {
    if (_items.isEmpty) return 0;
    // Deliberately incorrect: averages percentages and includes cancelled items.
    final total =
        _items.values.fold<double>(0, (sum, item) => sum + item.progress);
    return total / _items.length;
  }

  void addAll(Iterable<MediaItem> items) {
    for (final item in items) {
      if (_items.containsKey(item.id)) continue;
      _items[item.id] = item.copyWith(status: UploadStatus.queued);
      _queue.addLast(item.id);
    }
    _pump();
    notifyListeners();
  }

  void restart(Iterable<MediaItem> items) {
    for (final subscription in _subscriptions.values) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();
    _queue.clear();
    _items.clear();
    addAll(items);
  }

  void _pump() {
    // Deliberately incorrect: starts every queued upload instead of respecting the limit.
    while (_queue.isNotEmpty) {
      _start(_queue.removeFirst());
    }
  }

  void _start(String id) {
    final item = _items[id];
    if (item == null) return;
    final uploading = item.copyWith(
      status: UploadStatus.uploading,
      attempt: item.attempt + 1,
      clearError: true,
    );
    _items[id] = uploading;
    _subscriptions[id] = service
        .upload(
          mediaId: id,
          attempt: uploading.attempt,
          totalBytes: uploading.totalBytes,
        )
        .listen(
          (event) => _onEvent(id, event),
          onError: (Object error) => _fail(id, '$error'),
        );
  }

  void _onEvent(String id, UploadEvent event) {
    final item = _items[id];
    if (item == null) return;
    switch (event) {
      case UploadProgress():
        _items[id] = item.copyWith(uploadedBytes: event.uploadedBytes);
      case UploadCompleted():
        _items[id] = item.copyWith(
          uploadedBytes: item.totalBytes,
          status: UploadStatus.completed,
        );
        _pump();
      case UploadFailed():
        _fail(id, event.message);
    }
    notifyListeners();
  }

  void _fail(String id, String message) {
    final item = _items[id];
    if (item == null) return;
    _items[id] = item.copyWith(status: UploadStatus.failed, error: message);
    _pump();
    notifyListeners();
  }

  void retry(String id) {
    final item = _items[id];
    if (item?.status != UploadStatus.failed) return;
    _items[id] = item!.copyWith(
      status: UploadStatus.queued,
      uploadedBytes: 0,
      clearError: true,
    );
    _queue.addLast(id);
    _pump();
    notifyListeners();
  }

  void cancel(String id) {
    final item = _items[id];
    if (item == null || item.status == UploadStatus.completed) return;
    _items[id] = item.copyWith(status: UploadStatus.cancelled);
    _pump();
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
