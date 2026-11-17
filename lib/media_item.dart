// Candidate note: do not modify this file. The model and its behavior are part
// of the exercise contract. Make queue and progress-handling fixes in UploadManager.
// See QUESTIONS.md for the full edit boundaries.

enum MediaType { image, video }

enum UploadStatus { queued, uploading, completed, failed, cancelled }

class MediaItem {
  const MediaItem({
    required this.id,
    required this.name,
    required this.type,
    required this.totalBytes,
    this.uploadedBytes = 0,
    this.status = UploadStatus.queued,
    this.attempt = 0,
    this.error,
  });

  final String id;
  final String name;
  final MediaType type;
  final int totalBytes;
  final int uploadedBytes;
  final UploadStatus status;
  final int attempt;
  final String? error;

  double get progress => totalBytes <= 0 ? 0 : uploadedBytes / totalBytes;

  MediaItem copyWith({
    int? uploadedBytes,
    UploadStatus? status,
    int? attempt,
    String? error,
    bool clearError = false,
  }) =>
      MediaItem(
        id: id,
        name: name,
        type: type,
        totalBytes: totalBytes,
        uploadedBytes: uploadedBytes ?? this.uploadedBytes,
        status: status ?? this.status,
        attempt: attempt ?? this.attempt,
        error: clearError ? null : error ?? this.error,
      );
}
