# Media upload queue exercise

You’re working on a screen where users can upload photos and videos. The app already runs,
but a few things go wrong when uploads run together, fail, or get cancelled. Your task is to
make the queue behave reliably.

You have 90 minutes, including a short discussion at the end. The times below are a guide
to help you pace yourself. Keep the implementation offline using the simulated uploads
provided in the project. You don’t need to introduce a state-management package or rewrite
the app’s architecture.

## What you can change

Work in `lib/upload_manager.dart`, `lib/main.dart`, and `test/`. You may add helper
files under `lib/` and controlled upload-service fakes under `test/` if they help your
solution. Keep the existing public manager methods usable by the screen and tests.

Please leave these parts unchanged:

- `lib/media_item.dart`: the shared model, statuses, and progress calculation.
- `lib/upload_service.dart`: the upload events, service interface, and demo behavior,
  including the simulated first-attempt failure.
- The initial five media items in `lib/main.dart`, and the Add media and Restart demo
  controls. You can refactor the UI, but preserve this demo data and these behaviors.
- `pubspec.yaml`, `pubspec.lock`, `web/`, and the exercise instructions. No extra
  dependencies or platform setup are needed.

Fix the queue's handling of events rather than changing the simulator to avoid them.
If you think a change outside these boundaries is necessary, discuss it with the interviewer
before making it.

## How the queue should behave

Only two items should upload at a time. Everything else waits in the order it was added
(first in, first out, or FIFO). When an active upload completes, fails, or is cancelled, the
oldest eligible waiting item should take its place. Adding the same media ID again should
have no effect.

Each time an upload starts, including after a retry, it gets a new attempt number. Only
accept events from the current attempt while the item is uploading. This applies to progress,
completion, failure, stream errors, and stream closure. Progress must never go backwards or
exceed the file size: clamp incoming bytes to `[currentBytes, totalBytes]`. A successful
upload should finish at the full file size. If its stream closes before reporting completion
or failure, treat that attempt as failed.

Cancelling a waiting or active item is final: it should not start again or accept any more
events. A failed item can be retried. Retrying clears its error, resets its uploaded bytes to
zero, and puts it at the back of the queue. It starts a new attempt when a slot becomes
available. Changing one item must not interfere with another item’s upload.

Overall progress should reflect bytes uploaded, so a small photo and a large video don’t
carry equal weight. Calculate it as `sum(uploadedBytes) / sum(totalBytes)` across queued,
uploading, failed, and completed items. Leave cancelled items out of both sums. If the total
included bytes is zero, show zero progress.

When the manager is disposed, cancel its active subscriptions and make sure it sends no
further notifications.

## Q1 — Get the queue working (40 minutes)

Start with scheduling and progress. By the end of this part:

1. Adding five items should start exactly two and leave three waiting.
2. Completing or failing an upload should start only the oldest waiting item.
3. The number of active uploads should never exceed the configured limit.
4. Progress for an attempt should stay within bounds and never go backwards.
5. Overall progress should be based on bytes and exclude cancelled items.
6. Adding an existing ID should neither add a duplicate nor restart the upload.

## Q2 — Make retry and cancellation reliable (25 minutes)

Next, handle what happens when users cancel or retry an upload, or leave the screen:

1. A cancelled waiting item should never start.
2. Cancelling an active upload should free its slot and ignore any late events.
3. A retry should join the back of the queue with progress reset and get a new attempt
   number when it starts.
4. Events from an older attempt should not change a retried upload.
5. Stream errors and unexpected closure should fail only the item and attempt they belong to.
6. Disposing the manager should safely cancel all active subscriptions.

## Q3 — Keep the UI efficient (10 minutes)

Give each upload row a stable identity and avoid copying the full item collection for every
row lookup. Completed and failed rows should remain usable while other uploads continue.

Be ready to explain what you would change if the list grew to hundreds of items. A small,
focused improvement is enough here; a large architecture rewrite isn’t needed.

## Q4 — Cover the important behavior with tests (10 minutes)

Replace the two placeholder tests with:

1. A deterministic test for the two-upload limit and FIFO promotion.
2. A deterministic test for cancellation or retry with a late event from an old attempt.

Use streams you can control directly so the tests are repeatable. Don’t use network requests,
real files, timers, or sleeps in the tests.

## Review (5 minutes)

We’ll finish by talking through how you would take this into production. Where would media
picking, compression, multipart upload, authentication, persistence, background execution,
and retry backoff fit? Explain how you would keep those responsibilities separate from the
queue’s scheduling and state transitions.
