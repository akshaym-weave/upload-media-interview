# Media upload queue coding round

## Expected behavior demo

[Watch the reference solution demo](https://github.com/akshaym-weave/upload-media-interview/raw/refs/heads/main/docs/reference-demo.mp4)

This short, captioned recording shows the two-upload limit, FIFO promotion, failure
and retry, queued and active cancellation, and adding media. It demonstrates the expected
output; the starter project below still contains the exercise bugs.

Read `QUESTIONS.md` before changing code. The application runs, but queue limits, retry,
cancellation, aggregate progress, and stream cleanup are deliberately incorrect.

See **What you can change** in `QUESTIONS.md` for edit boundaries. The main working
files are `lib/upload_manager.dart`, `lib/main.dart`, and `test/`; the shared model
and upload simulator must stay unchanged.

## Setup before the clock

```sh
flutter --version
flutter pub get
flutter analyze
flutter run -d chrome
flutter test
```

The app uses simulated local media and progress streams. Keep the solution offline and
explainable. No particular state-management package is required.
