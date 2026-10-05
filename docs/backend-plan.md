# Backend plan: Serverpod (Steps 7a, 7b and 8)

Approved on 3 October 2026. It replaces the Dart Frog and Supabase plan approved on 1 October and keeps that plan's pipeline, privacy rules and additions. CLAUDE.md has the summary and the working rules; this file has the detail. When a decision changes, change it here first.

Everything here serves the hackathon (see "Hackathon alignment" in CLAUDE.md): the real pipeline with nothing faked, Serverpod doing the real work, and a backend judges can test without being able to exhaust our Groq or Gemini quota.

## The decisions

### a. Database and storage

**Serverpod's own Postgres, and Serverpod Cloud's file storage. No Supabase, no R2.**

- **Database:** Serverpod's database layer, migrations, auth module and future calls all live in its own Postgres.
  - Locally it's Serverpod's embedded Postgres.
  - In production it's Serverpod Cloud's managed Postgres 17.
- **Storage:** audio goes in Cloud's `private` storage through `session.storage`. Locally, the same calls store files in the database, so the code doesn't change.
- **Why not Supabase:** it would only add a second database host, storage API, account system and bill, a network hop away from the server.
- **R2** matters only if we ever host the server ourselves. Serverpod has an R2 adapter (`serverpod_cloud_storage_r2`).
- **Connection pooling:** Cloud's Postgres pools connections. So every lock is transaction-scoped (`SELECT … FOR UPDATE`, `pg_advisory_xact_lock`), never a session-level advisory lock.

### b. Accounts

**Serverpod's auth module (`serverpod_auth_idp`), built first in Step 7a, before anything is deployed.**

- **Sign-in:** email and password.
  - **Codes:** Serverpod Cloud's built-in email service sends the sign-up and password-reset codes (`ServerpodCloudEmailIdpConfig`). In the development and test modes they're written to the server log instead.
  - **Tokens:** JWT, the template default.
  - **Brute force:** the module limits failed sign-ins, code attempts and password resets itself.
- **Every endpoint requires sign-in from its first version** (`requireLogin`). There's no `APP_SECRET` at any point, and the backend is never public without accounts.
- **Judge account:** a small admin command creates it with `EmailIdpAdmin.createEmailAuthentication` and marks it as reserved (see "Limits").
  - The password goes only in the submission form's testing instructions, never in git.
- **Sign-up stays open,** so judges can try it. Per-account limits, global caps and two switches (sign-ups open, processing paused) protect the shared quota.
- **The app's screens are our own,** in Paper & Ink, built on the module's email flow (its `EmailAuthController`, or the generated email endpoints directly).
  - **Why not the ready-made sign-in widgets:** they import Flutter's own `package:flutter/material.dart`, so under our theme rules they wouldn't see our theme. They'd also bring Google and Apple sign-in and runtime font downloads.
- **Later:** Google and Apple sign-in, and in-app account deletion (which the stores require).

### c. Background jobs

**Serverpod future calls run the work. Our `job` table records progress.**

- **What future calls guarantee:** a future call is stored in the database. One server claims it, and sends a heartbeat every minute while it runs. If that server dies, another one, or the same one after a restart, takes the call over once the claim is 3 minutes old. So a call runs at least once and survives crashes. This is checked in the 4.0.3 source (`future_call_manager.dart`).
- **Making "at least once" act like "once":**
  - Finishing an upload schedules `processJob(noteId)`, with the note id as its identifier, so cancelling removes it.
  - The job row keeps the status and a checkpoint per step. Each part's transcript is saved the moment Groq returns it. So a rerun never repeats a Groq call for a finished part, nor a Gemini call for a saved note.
- **Errors:** Serverpod doesn't retry a call that throws, so the job runner catches everything.
  - A retryable error (429, 5xx, timeout) schedules the job again with backoff.
  - A permanent one marks it `failed` with a code.
- **Waiting:** when the rate limiter has no room, or `Retry-After` is longer than about a minute, the job reschedules itself for that time and returns. It never holds a server slot while waiting.
- **A recurring sweeper** (`callRecurring` every 5 minutes, with an identifier):
  - re-queues jobs that are unfinished but have no pending call, for example one dropped as "broken" after a code change
  - deletes audio on schedule
  - removes abandoned uploads
- **Settings:** `futureCall.concurrencyLimit` 3 and `scanInterval` 1000 ms, to tune.
- **Plan:** future calls are off on Serverpod Cloud's Starter plan, so we use the Growth plan ($20 a month plus usage).
- **Scaling later:** run API servers with `futureCall.executionEnabled: false` and separate worker servers with it on. No code change.

### d. Uploads

**Resumable chunks of about 1 MB with byte offsets, safe to repeat, keyed by the note's UUID, through typed endpoint calls.**

- **Upload after the recording stops.** Discarded recordings are never sent, and uploading can't disturb recording.
- **The calls:** see "Calls" below.
  - A chunk at the wrong offset gets a typed error carrying the current offset, the same idea as tus's 409. The app resumes exactly there, even after a restart.
- **Where chunks go:** each chunk goes to `private` storage as `uploads/<user id>/<note id>/<offset>`. The job row's byte count is updated in a transaction that locks that row, so retries can't append twice.
- **Why not Serverpod's own `FileUploader`:** it sends a whole file in one request, can't resume, reports no progress, and returns `false` with no reason on failure.
- **Trade-off:** `ByteData` in an endpoint call travels as base64 inside JSON, about a third larger. An hour is 15 MB of audio and about 20 MB on the wire.
  - `maxRequestSize` goes from 512 KiB to 2 MB.
  - If the overhead matters on slow networks, a raw-bytes upload route is the fallback.
- **Validation:**
  - The declared size must fit a 3-hour recording with a margin: 3 h is about 45 MB, and the cap is 60 MB.
  - The account must have the minutes left. The estimate is about 4,000 bytes per second.
  - Size and SHA-256 are checked at `complete`.
  - That the file is valid ADTS is checked first thing in the job, before any AI call.
- **Abandoned uploads:** jobs still `uploading` with no chunk for 3 days (configurable) are deleted with their chunks by the sweeper.

### e. Job status

**A streaming endpoint, not polling.**

- **`jobs.watch()`** streams the signed-in user's unfinished jobs: the current state first, then every change. The processing screen and Home update live: uploading, queued, transcribing, writing notes, ready.
- **How changes reach the stream:**
  - **Same server:** the job runner posts each change as a server event (`session.messages`, default scope), so a stream on that server hears it at once.
  - **Several servers:** Cloud has no Redis, so the stream also re-reads the user's jobs every few seconds, which keeps it correct anyway. With Redis added later, events reach every server with no code change.
- **The app:**
  - It opens the stream while it's on screen. The stream closes in the background.
  - It asks for the current state once on launch and on resume.
  - It reconnects with backoff when the connection drops.
- **Later:** a push notification when a note is ready while the app is closed.

### f. No ffmpeg

**Serverpod Cloud builds our Dart code itself: no Dockerfile, no system packages. The audio work is pure Dart in `packages/echonotes_audio`.**

- **Repackaging:** a small writer wraps the same AAC frames in an `.m4a` (MP4) container: `ftyp`, `moov` with an `mp4a`/`esds` track built from the ADTS header, and `mdat`. There's no re-encoding.
  - It's checked with `ffprobe` (Homebrew ffmpeg, tests only) and with one real Groq call early in Step 7b.
- **Quiet moments for cuts:** start with AAC frame sizes, because silence encodes into much smaller frames. No app change is needed, and it works on recovered recordings too.
  - Check it on real recordings from both phones in Step 7b.
  - If one platform pads its frames to a constant size, the app saves its level readings as a small side file (about 36 KB an hour) and uploads it with the audio (Step 8).
  - The splitter takes "loudness per frame" from either source.
- **Only long recordings are split:** over about 1 h 40 min (24 MB, under Groq's 25 MB free-tier file limit). So this never touches a short demo, and correctness at the cuts comes from the overlap and the merge anyway.
- **Bonus:** the same writer can repackage recordings on the phone if iOS seeking turns out imprecise (Later item 5). The package is also the shared ADTS code the app moves onto later (Later item 11).

### g. Local development

- **No Docker:** the embedded Postgres runs in the development and test modes.
  - The first start downloads its binaries once, into `~/Library/Caches/serverpod/pg-binaries`. That's slow on a slow connection.
  - Integration tests (`withServerpod`) each get a throwaway database.
- **Run it** with `fvm exec serverpod start --no-flutter` from `server/`. FVM puts the pinned Flutter and Dart first, and the Mac's global Flutter is too old for Serverpod 4. In a shell without a terminal, add `--no-tui`.
- **Serverpod CLI 4.0.3,** the same version as the packages, installed with the pinned Dart.

## Layout

```
echonote/
├── pubspec.yaml                 # pub workspace: app, client, server, packages/*
├── app/                         # the Flutter app (Dart package `echonotes`)
├── client/                      # `echonotes_client`, generated by `serverpod generate`; never edited
├── server/                      # `echonotes_server`, the Serverpod server
│   ├── bin/main.dart, lib/server.dart
│   ├── config/                  # run modes, generator.yaml, passwords.yaml (gitignored)
│   ├── migrations/              # Serverpod migrations; never edited after release
│   ├── lib/src/
│   │   ├── core/                # settings, logging rules, backoff, errors
│   │   ├── accounts/            # auth setup, limits and switches, the judge-account command
│   │   ├── uploads/             # UploadsEndpoint, chunk storage
│   │   ├── jobs/                # Job model, JobsEndpoint (status, watch, note, retry, cancel),
│   │   │                        # ProcessJob and Sweeper future calls, the job runner
│   │   ├── transcription/       # TranscriptionService, GroqTranscriptionService, TranscriptMerger
│   │   ├── notes/               # NotesService, GeminiNotesService, schema and validation
│   │   └── rate_limits/         # RateLimiter, PostgresRateLimiter
│   ├── tool/process_recording.dart
│   └── test/                    # unit tests, and integration tests on the embedded Postgres
└── packages/echonotes_audio/    # pure Dart: ADTS reader, .m4a writer, splitter
```

- **Setting it up:** generate Serverpod's template in a scratch folder and copy in only the server and client parts. That way it can't overwrite our CLAUDE.md, `.vscode` or `.gitignore`. Also take its agent skills and MCP config for Claude.
- **Serverpod Cloud** deploys the server's local workspace packages along with it.
- **Wiring:** services sit behind interfaces. `server.dart` creates the implementations at startup, and endpoints and future calls reach them through one small services object that tests can swap. This replaces Dart Frog's middleware wiring.

## Data model (first draft; Step 7a settles the details)

| Table | What it holds |
|---|---|
| `job` | One per recording. The id is the note's UUID. Also: user, status, error code, declared size, bytes received, SHA-256, exact duration, attempts, last activity, when the audio is due for deletion. |
| `job_part` | Transcription checkpoints: part index, start and end, Groq's segments. Saved the moment each part is done. |
| The finished note | Title, summary, language and tags, plus key points, action items and transcript segments, each with its own id for sync (Later item 3). Stays on the server until the note is deleted. |
| `ai_call` | One booking per Groq or Gemini call: provider, time, and requests, audio seconds or tokens. |
| `usage_record` | Audio seconds per job and user. |
| Account settings | Per-user overrides: reserved (the judge account), blocked, custom limits. |
| Server switches | Sign-ups open, processing paused. Changeable without a redeploy. |

The auth module adds its own tables.

## Calls (the generated client)

Every call requires sign-in, and a user only ever sees their own jobs.

| Call | What it does |
|---|---|
| Auth module's email calls | Sign up with a code, sign in, reset the password, sign out |
| `uploads.start(noteId, size)` | Creates the job, and is safe to repeat. Checks the size cap, the account's minutes, the global cap and the switches. Returns the status and the bytes received. |
| `uploads.offset(noteId)` | How many bytes have arrived |
| `uploads.appendChunk(noteId, offset, bytes)` | Stores the next chunk. A wrong offset is a typed error with the current offset; a cancelled job is a typed error too. |
| `uploads.complete(noteId, size, sha256)` | Marks the upload finished and queues the job |
| `jobs.get(noteId)` | The current state, with an error code when the job failed |
| `jobs.watch()` | A stream of the user's unfinished jobs (see "Job status") |
| `jobs.note(noteId)` | The finished note |
| `jobs.retry(noteId)` | Tries a failed job again, without a new upload while its audio is kept |
| `jobs.cancel(noteId)` | Stops the job and deletes its audio, transcript and note at once. The job stays as `cancelled`, a server-only status, so late chunks are refused instead of reviving it. |

Health checks are Serverpod's built-in ones.

## What happens to each recording

1. **`uploading`:** chunks arrive. `complete` checks size and SHA-256, moves the job to **`queued`** and schedules `processJob`.
2. **`transcribing`:**
   - **Prepare:** read the chunks part by part, never the whole recording in memory. Check that it's valid ADTS. Get the exact duration from the frames (1,024 samples each) and record the audio seconds in `usage_record`. Invalid audio fails with `invalid_audio`.
   - **Split:** files over 24 MB (configurable) are split into equal parts.
     - Each cut moves to the quietest stretch within 30 seconds of it.
     - Cuts land on a frame boundary, and neighbouring parts overlap by 2 seconds.
     - The splitter is pure Dart: frames and loudness go in, a cut plan comes out.
   - **Transcribe:** each part becomes an `.m4a`, goes to Groq (`whisper-large-v3-turbo`, `verbose_json` with segment timestamps), and is saved as a checkpoint.
   - **Merge:**
     - Timestamps shift by where each part starts.
     - Speech near a cut is kept from one side only.
     - Words repeated across a cut are removed by matching the end of one part with the start of the next.
     - Segments Whisper marks as non-speech are dropped; these are its typical "Thank you." on silence.
     - A recording with no speech fails with `no_speech` instead of getting made-up notes.
3. **`writing_notes`:**
   - **The call:** one Gemini call with a JSON schema: title, a summary of 3–5 sentences, key points, action items, up to 5 tags, and language. The notes are written in the transcript's language. The model comes from settings, starting with `gemini-3.5-flash-lite`.
   - **The API:** the Interactions API with `store: false`. If it gives trouble in the first real call, switch to `generateContent` behind the same interface. Either way, confirm in that first real call that nothing is stored.
   - **Checking:** every field is checked. Malformed JSON is retried twice, then the job fails with `bad_notes`.
   - **Long transcripts:** over about 2 hours of speech (configurable), each part gets its own notes and one more call combines them.
4. **`ready`:**
   - The note is saved with an id for every part.
   - The audio is deleted 1 hour after success. A failed job keeps its audio for 3 days, so "Try again" needs no new upload. Both times are configurable.

## Limits

- **Rate limiter:** every Groq and Gemini call is booked first in `ai_call`, inside a transaction that locks the provider's row. So the limits hold across every server.
  - **Groq free tier:** 20 requests a minute and 2,000 a day; 7,200 audio seconds an hour and 28,800 a day. That last one is 8 hours of audio a day for everyone together. Groq bills at least 10 seconds per request.
  - **Gemini:** requests a minute and a day, and tokens a minute. Free-tier quotas are only shown in AI Studio, so read them there.
  - **Settings:** all limits are settings, so a paid tier is a settings change.
- **Retries:** 429s, 5xx errors and timeouts back off (1, 2, 4 … 60 seconds) and respect `Retry-After`. Longer waits reschedule the job. Permanent errors fail at once with a clear code.
- **Per account** (defaults to tune): 60 minutes of audio a day and 300 a month. The reserved judge account gets 180 a day.
- **Global:** 6 hours a day for everyone, under Groq's free 8. Part of it (3 hours to start) is reserved for reserved accounts, so strangers can't use up judging capacity.
- **Where they're checked:**
  - At `uploads.start`, from the size, so a user over the limit hears it before uploading.
  - Recorded exactly once the duration is known.
  - A user over the limit gets a clear typed error the app can explain.
- **Switches:** close sign-ups, and pause processing. Paused jobs wait in the queue; nothing fails.

## Privacy

- **Logs** hold only ids, statuses, sizes, timings and error codes. Never transcript or note text, never keys.
- **Gemini** is called with `store: false`, and Groq's Zero Data Retention is turned on in its console.
- **Audio is deleted** 1 hour after success, 3 days after failure, and at once on cancel.
- **Notes** stay on the server for sync until the user deletes the note.
- **Before judges get access:** switch Gemini to the paid tier, because on the free tier Google may use what we send. See "Release".

## Secrets and settings

- **Locally:** `server/config/passwords.yaml` holds the Groq and Gemini keys. It's gitignored, and a committed `passwords.example.yaml` lists the names. The user fills in the real values.
- **On Serverpod Cloud:** `serverpod cloud password set <name> <value>`. Cloud injects the database password and the auth email key itself.
- **Plain settings** (model name, limits, retention times) live in config or environment variables. They aren't secrets, but they're never hard-coded in more than one place.

## Hosting

- **Serverpod Cloud, Growth plan.** The default addresses are:
  - API: `https://<project>.api.serverpod.space/`
  - Web: `https://<project>.serverpod.space/`
  - Insights: `https://<project>.insights.serverpod.space/`
- **Deploy** with `fvm exec serverpod cloud deploy` from `server/`. Migrations apply on deploy.
- **Before the first deploy in Step 7a,** run `serverpod cloud deploy --wet-run --show-files`, and check two things:
  - Cloud accepts our folder names (`server/` and `client/` rather than `*_server` and `*_client`).
  - Cloud has Dart 3.13.4. If it doesn't, the server's constraint becomes `^3.13.0`.

## Tests

- **Unit tests** (plain `dart test`):
  - the ADTS reader, the `.m4a` writer and the splitter
  - the merge, and the rate limiter's time windows
  - backoff and `Retry-After`
  - both AI services with fake HTTP: request shape, parsing, 429 and 5xx, malformed JSON
  - schema validation
- **ffmpeg tests** (tagged, Mac only): `ffprobe` reads our `.m4a` with the same codec and duration.
- **Integration tests** (`withServerpod` on the embedded Postgres):
  - every call refuses a signed-out user
  - upload offsets and repeats, including two chunks arriving at the same time, plus the validation and the limits
  - the job runner: a rerun repeats no AI call, and cancel and retry work
  - the limiter's bookings hold under concurrency
- **The test script:** `fvm dart run tool/process_recording.dart <file.aac>`.
  - It signs in with a test account, uploads in chunks, prints each status change and then the note.
  - `--interrupt` shows a dropped upload resuming, and `--note-id` shows that a repeated upload creates no new job.
  - A small split limit setting forces a short recording to be split.
- **Real calls:** one Groq call (it accepts our `.m4a`) and one Gemini call (`store: false` holds), once the keys are in `passwords.yaml`.

## The app side (Step 8)

- **Interfaces in `domain/`:**
  - `NoteProcessingService`: upload, status updates, fetch the finished note, retry, cancel.
  - `AuthService`: sign up, sign in, sign out, the current user.
- **Implementations in `data/`:** `ServerpodNoteProcessingService` and `ServerpodAuthService`. Only these use the generated client, and they convert its types into our domain models.
  - A guard test fails if `package:echonotes_client` is imported outside `data/`.
  - The `Client` and the server address live in `core/` (the address is passed at build time; it isn't a secret).
- **What gets built:**
  - **`FakeNoteProcessing` is deleted.** Unfinished notes upload and process for real, including those left over from a closed app and those found by recovery.
  - **Uploads** resume where they stopped, also after the app restarts.
  - **Live status** comes through the stream, and the finished note is saved in Drift.
  - **Deleting a note** that's still processing cancels its job.
- **Unhappy paths:**
  - no internet, or the server unreachable: the note waits and retries
  - signed out
  - over a limit: the app says which, and when it resets
  - processing paused, and failed jobs with their reason
- **Sign-in, sign-up and password reset screens** in Paper & Ink, with widget tests and the small-screen test.
- **Until Step 6 exists,** the recording screen shows a plain message about the transcript coming after the recording, instead of today's "live preview is coming soon" card. That card reads as unfinished in a demo.
- **Home's search field is only a look today** (`NotesSearchField`: "searching arrives with the database"). A judge typing in it would see nothing happen. Either make a simple search work (title, summary and tags, in Drift) or hide the field until Step 10. Decide in Step 8's plan.

## Steps

| Step | When | Done when |
|---|---|---|
| 7a | 4–5 Oct | The workspace builds, accounts work, the upload and status calls are tested, and the first deploy to Serverpod Cloud is live |
| 7b | 6–8 Oct | A real recording goes through Groq and Gemini to a finished note: locally with the test script, then on Cloud. Limits, clean-up and tests are done. |
| 8 | 9–11 Oct | The app runs the real flow end to end on a real phone. `FakeNoteProcessing` is gone. |
| Release | 12 Oct | Signed APK with a download link, judge account, README and `docs/SUBMISSION.md` finished, TestFlight if possible |

## Release: before judges get access

- **Gemini paid tier:** remind the user to switch, with the exact steps checked against Google's docs on that day. Raise it at the start of Step 8, so billing has time to settle.
- **Groq Zero Data Retention:** check it's on.
- **The judge account:** create it, mark it reserved, and put its credentials only in the submission form.
- **What judges see first:** replace Flutter's default app icon and launch screen with EchoNotes' own. Android also shows the app icon in the recording notification. Check the cold start on a real phone too; on the 8 GB Mac's emulator, the release build took about 14 seconds to show Home.
- **Limits and caps:** check the settings and the two switches.
- **Freeze:** from submission until judging ends (20 October, 17:00 CEST), the deployed backend and the APK stay exactly as submitted. New work goes on a branch.

## Risks

- **Time:** 11 days for Steps 7a, 7b, 8 and the release. Deploying on day 2 is the main protection.
- **Serverpod 4 and Serverpod Cloud are about three weeks old,** so expect rough edges. Stay on 4.0.3, check the docs before each piece, and note the issues we hit for the hackathon's feedback form.
- **Unproven ideas:** frame sizes as a quietness signal (iOS especially), and our `.m4a` writer with Groq. Both are tested early in Step 7b.
- **Serverpod Cloud's email service** has no published sending limits. Test a real sign-up right after the first deploy.
- **This Mac has 8 GB of memory.** An Android emulator and a Gradle build at the same time starve each other, so run them one after the other.
