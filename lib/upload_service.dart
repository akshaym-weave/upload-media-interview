// Candidate note: do not modify this file, including the simulated failure.
// Handle these events in UploadManager. For tests, implement a controlled
// UploadService fake under test/ instead of changing the demo service.

sealed class UploadEvent {
  const UploadEvent();
}

class UploadProgress extends UploadEvent {
  const UploadProgress(this.uploadedBytes);
  final int uploadedBytes;
}

class UploadCompleted extends UploadEvent {
  const UploadCompleted();
}

class UploadFailed extends UploadEvent {
  const UploadFailed(this.message);
  final String message;
}

abstract class UploadService {
  Stream<UploadEvent> upload({
    required String mediaId,
    required int attempt,
    required int totalBytes,
  });
}

class DemoUploadService implements UploadService {
  const DemoUploadService({this.tick = const Duration(milliseconds: 300)});
  final Duration tick;

  @override
  Stream<UploadEvent> upload({
    required String mediaId,
    required int attempt,
    required int totalBytes,
  }) async* {
    const steps = 10;
    for (var step = 1; step <= steps; step++) {
      await Future<void>.delayed(tick);
      if (mediaId == 'video-1' && attempt == 1 && step == 5) {
        yield const UploadFailed('Simulated connection loss');
        return;
      }
      yield UploadProgress((totalBytes * step / steps).round());
    }
    yield const UploadCompleted();
  }
}
