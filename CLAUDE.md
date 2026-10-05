# EchoNotes

EchoNotes is a Flutter app for Android and iOS. It records conversations (meetings, lectures, interviews) and turns them into organized notes with AI.

EchoNotes is our entry in Serverpod's "Build Something Real" hackathon, and submissions close on **14 October 2026 at 23:59 CEST**. Read "Hackathon alignment" first: it decides what gets built, and in what order.

The project is built one step at a time (see "Steps"). So far:
- the scaffold and the design system
- the main screens: home, recording, processing and note detail
- the local database, where notes are saved for real
- real recording, which carries on in the background and with the screen locked (Steps 5a and 5b)

Processing is still pretend, and `server/` is still the Dart Frog starter. The real backend, on Serverpod, comes next: Steps 7a and 7b build it, and Step 8 connects the app. `docs/backend-plan.md` has the detailed plan. The rest of this file describes the target design.

## Hackathon alignment

EchoNotes is entered in "Build Something Real: The Serverpod Hackathon". Keep this section in mind in every step: each step should move what the judges will test forward.

- **Dates:**
  - Submissions close **14 October 2026 at 23:59 CEST** (22:59 WAT), with no extensions.
  - Judging runs from 15 to 20 October, until 17:00 CEST.
  - Winners are announced on 22 October.
- **Rules,** checked by the user against the official PDF on 3 October:
  - Only new projects count. Ours began on 30 September.
  - AI tools are allowed, but the text description must say which ones.
  - A private repo must be shared with viktor@serverpod.dev, alexander@serverpod.dev and isak@serverpod.dev.
  - The demo video is under 2 minutes, public on YouTube or Vimeo, and shows the app on a real phone.
  - The testing instructions include login details.
  - Everything is in English.
  - The project stays testable, free of charge, until judging ends.

### What the judges look for, and what it means for us

| Criterion | Weight | For us |
|---|---|---|
| Does it work | 30% | It runs, the core flow completes, and nothing critical is faked. `FakeNoteProcessing` is fully replaced by the real pipeline. Nothing on screen looks unfinished: the recording screen's "live preview is coming soon" card gives way to a plain message until Step 6 exists, and Home's search field (only a look today) either works or is hidden. |
| Use of the Serverpod stack | 25% | Serverpod does the real work: typed endpoints, the auth module, resumable uploads, future calls for the pipeline, a streaming endpoint for live status, and its Postgres and file storage, all hosted on Serverpod Cloud. |
| Craft and technical creativity | 25% | Careful, well-built work: tested, the unhappy paths handled, privacy respected, the shared AI quota protected. |
| Usefulness | 20% | A clear user with a clear problem: people in meetings, lectures and interviews who want to listen instead of typing, and still leave with organized notes. The demo and `docs/SUBMISSION.md` tell one user's story, chosen before the video. |

### Judges can test it themselves

- The backend is deployed on Serverpod Cloud.
- The submission links to an Android build judges can install. iOS goes through TestFlight if an Apple developer account is available.
- A judge test account exists. Its credentials go only in the submission form, never in git.
- Per-account usage limits plus global caps mean testing can never exhaust our Groq or Gemini quota. See "Limits" in `docs/backend-plan.md`.
- Accounts exist before the backend goes public. Every endpoint requires sign-in from Step 7a on, and there's no `APP_SECRET`.
- **Gemini's paid tier:** before the backend goes public for judges, at the release step, remind the user to switch Gemini to its paid tier. Give the exact steps, checked against Google's docs that day. Raise it first at the start of Step 8, so billing has time to settle.

### Submission materials, kept up to date as we build

- A private GitHub repository the user owns. The user runs every git and GitHub command (see "Git" under "How to work on this project").
- `README.md` at the root: what EchoNotes is, and how to build, run and test it.
- `docs/SUBMISSION.md`: the features, how it was built, and the AI tools used (Claude Code with Claude Opus 5.5).
- A demo video under 2 minutes on a real phone: sign in, record, stop, watch the live status, read the note, play it back. The core flow must be smooth enough for that.
- Everything in English.
- **Optional:** the "Most valuable feedback" prize ($500, plus $500 in Cloud credits) rewards actionable feedback on Serverpod. Note the Serverpod issues we hit in `docs/serverpod-feedback.md` as they come up.

### During judging

From submission until 20 October at 17:00 CEST, the deployed backend and the APK stay exactly as submitted. New work goes on a branch, and nothing is deployed over the judged version.

## Steps

| Step | When |
|---|---|
| 1–4: scaffold, design system, main screens, local database | Done |
| 5a and 5b: real recording, in the background and with the screen locked | Done |
| Toolchain upgrade: Flutter 3.47.5 through FVM, AGP 9.1, the iOS scene lifecycle | Done (2 and 3 October) |
| 0: hackathon plan, this file, `docs/`, Supabase CLI removed | 3 October |
| 7a: Serverpod workspace, accounts, upload and status calls, first deploy to Serverpod Cloud | 4–5 October |
| 7b: the real pipeline: audio package, Groq, Gemini, rate limiter, future calls, limits, clean-up | 6–8 October |
| 8: the app on the real backend: sign-in, uploads, live status, notes. `FakeNoteProcessing` is deleted. | 9–11 October |
| Release: signed APK and its download link, judge account, Gemini's paid tier, the EchoNotes app icon and launch screen (both still Flutter's defaults), README and SUBMISSION.md finished, TestFlight if possible | 12 October |
| Demo video (by the user), and fixes | 13 October |
| Submit, in the afternoon | 14 October |

- **If we're ahead of schedule,** pull work forward in this order:
  1. Step 9 (tap-to-seek)
  2. Step 10 ("Ask your notes")
  3. a visual polish pass
  4. Step 6 (the live transcript preview)
- **After submitting,** on a branch until judging ends: whatever is left of Steps 9, 10 and 6, then the full redesign and the store launch (see "Later").
- **Step 11** (accounts) became part of Step 7a.

## How it works

1. **Record.** While recording, the app shows a rough live transcript preview (Step 6). The accurate transcript comes from step 3.
   - **From the audio already recorded.** The preview never opens the microphone. The app decodes the AAC frames the recorder already writes back to PCM and hands them to the phone's own speech recognizer, so a failing preview can't touch the recording (see "Open risks").
   - **Recognizers:** Apple's `SpeechAnalyzer` with `SpeechTranscriber` on iOS 26 and later (`DictationTranscriber` where `SpeechTranscriber` isn't available), and Google's ML Kit speech recognition on Android 12 and later, given our audio with `AudioSource.fromPfd`. Other phones get no preview, and the card says the full transcript comes after the user stops.
   - **Only while it can be seen:** it runs while the recording screen is visible and recording, and stops on pause, in the background and with the screen locked. Its text is never saved.
2. **Upload.** When the user stops, the app uploads the audio to our Serverpod backend in resumable chunks of about 1 MB. After a dropped connection or an app restart, it carries on where it stopped.
3. **Transcribe.** A Serverpod future call (a background job) takes it from there.
   - It repackages the audio as `.m4a` in pure Dart and splits long recordings.
   - It sends them to Groq Whisper (`whisper-large-v3-turbo`), which returns a transcript with timestamps.
4. **Summarize.** The same job sends the transcript to the Google Gemini API, which returns JSON: `title`, `summary`, `key_points`, `action_items`, `tags` and `language`.
5. **Save and show.**
   - The app follows each step live through a streaming endpoint.
   - When the job is done, the app fetches the note, saves it in its local database, and shows it as a clean note.

## Tech stack

| Part | Choice |
|---|---|
| App | Flutter (Android + iOS) |
| Material and Cupertino widgets | The `material_ui` and `cupertino_ui` packages, not Flutter's built-in copies (see "Theme rules") |
| State management | Riverpod (`flutter_riverpod`, no code generation) |
| Navigation | `go_router` |
| Local database | Drift (SQLite) via `drift_flutter` |
| Recording | `record` |
| Live transcript preview | Apple `SpeechAnalyzer` (iOS 26+) and Google ML Kit speech recognition (Android 12+), fed the recorder's own audio |
| Playback | `just_audio` |
| Backend | Serverpod 4.0.3, so the whole project is Dart, hosted on Serverpod Cloud (Growth plan) |
| Server database and files | Serverpod's Postgres (embedded locally, managed Postgres 17 on Cloud) and Serverpod Cloud's file storage |
| Accounts | Serverpod's auth module (`serverpod_auth_idp`): email and password, with codes sent by Serverpod Cloud's email service |
| Background jobs | Serverpod future calls |
| Live job status | A Serverpod streaming endpoint |
| App to server | The client Serverpod generates (`echonotes_client`), used only in `data/` |
| Transcription | Groq Whisper `whisper-large-v3-turbo`, called from the backend only |
| Notes | Google Gemini API (the Interactions API, with `generateContent` as fallback), called from the backend only |

Toolchain: **Flutter 3.47.5 with Dart 3.13.4**, pinned for this project with FVM in `.fvmrc` (see "How to work on this project"). The Mac's global Flutter is an older version kept for other projects, so never use it here.

- Every pubspec requires the pinned SDK (`sdk: ^3.13.4`, and `flutter: ">=3.47.5"` in the app), so an older SDK fails at `pub get` instead of building.
- Serverpod Cloud builds the server with the Dart its pubspec allows. Cloud supports 3.8 to 3.13.
- All `serverpod*` packages and the Serverpod CLI (`serverpod_cli`) share one exact version: 4.0.3.
- VS Code picks the pinned SDK up from `.vscode/settings.json`.
- **Android:** AGP 9.1, Gradle 9.3.1, Kotlin 2.4 and Java 17, as in Flutter 3.47's own template. Kotlin comes from Flutter's Gradle plugin: `android.builtInKotlin` and `android.newDsl` stay `false` until Flutter and every plugin support AGP 9's defaults. compileSdk is 37, because `permission_handler` 13 compiles against it. NDK 28.2. minSdk and targetSdk follow Flutter (24 and 36).
- **iOS:** iOS 15 or later. Plugins come in through Swift Package Manager, with no CocoaPods. The app uses the scene lifecycle (`UIScene`), which Xcode 27 requires. Plugins and the `echonotes/device` channel are set up in `didInitializeImplicitFlutterEngine` in `AppDelegate.swift`, not at launch.

## Design system: "Paper & Ink"

Calm, premium and focused, like a good paper notebook that listens. Warm paper backgrounds, ink-dark text and one red-orange accent that marks recording. Dark mode is "lamplight": warm near-black, never blue-black. The app follows the phone's light/dark setting (`ThemeMode.system`).

- **Fonts:** Fraunces SemiBold for headings (`display*`, `headline*`, `titleLarge`) and Inter for everything else. Both are bundled in `app/assets/fonts/`, so nothing is downloaded at runtime. The README there explains how to add a weight.
- **Shape:** flat cards with a 1px `border` instead of shadows. Corners use `AppRadius`: `sm` 8 for tags, `md` 12 for buttons and fields, `lg` 16 for cards, `xl` 24 for sheets and dialogs.
- **Spacing:** a 4-point scale in `AppSpacing` (`xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 24, `xxl` 32, `xxxl` 48). Screen side margins use `AppSpacing.page` (24).
- **Record button:** `RecordButton` in `core/widgets/` is an accent disc inside an ink ring. While recording it turns into a stop square, and soft rings spread out and follow the voice level. While paused, the rings rest. Leave `RecordButton.footprint` of room when it floats over content.
- **Screen transitions:** each platform's own (iOS slide with swipe back, Android Material 3 fade), set in `AppTheme`. The recording screen instead rises in with `RiseInPage` (`app/rise_in_page.dart`).
- **Design preview:** in debug builds, the palette icon on the home screen opens `/design`. It shows every token and key component and can switch between light and dark. Check new UI there in both modes.

### Theme rules

- **Material and Cupertino** come from `package:material_ui/material_ui.dart` and `package:cupertino_ui/cupertino_ui.dart`, never from Flutter's own `package:flutter/material.dart` or `package:flutter/cupertino.dart`. Those are separate copies with the same class names, and editors offer both when adding an import. A widget built from Flutter's copy doesn't see the app's theme, and `go_router` doesn't recognise an app built from it, so screens open with no transition and no iOS swipe-back. Nothing crashes, so `test/app/material_imports_test.dart` checks the imports and `app_test.dart` checks that screens open as Material pages.
- **Colors** always come from the theme: `context.colors` (`AppColors`: `background`, `card`, `textPrimary`, `accent`, `success`, `error`, …) or `Theme.of(context).colorScheme`. Never use `Color(0x…)` or `Colors.*` in a widget.
- **Text** uses `context.textTheme` roles (`titleLarge`, `bodyMedium`, …) or `AppTextStyles` extras (`timer`). Only override the color, and take it from the theme. Never set a font size or family in a widget.
- **Spacing, corners and motion** use `AppSpacing`, `AppRadius` and `AppMotion`, never inline numbers. A size that belongs to a single component is a named constant in that component.
- **New tokens:** need a new color, text style or size? Add it in `app/lib/core/theme/` (for colors, in both light and dark) and show it on the design preview. Text must meet WCAG AA contrast (4.5:1). `app_colors_test.dart` checks the color pairs.
- **Errors** always show an icon and a message, never color alone. The error red is close in hue to the accent.
- **Motion** respects `MediaQuery.disableAnimationsOf(context)`. When it's on, looping animations become a still state.

### Ready for the redesign

The whole UI will be redesigned after Step 8, once the hackathon is over. Before then there's at most a visual polish pass, if we're ahead of schedule. Build every screen so its look can be replaced without touching recording, database or backend code. The theme rules above say where styling values come from; these rules say where styling and logic may live.

- **Styling lives in the theme and in small reusable widgets.** Colors, text styles, sizes and decoration are applied only inside small components. Shared ones go in `core/widgets/` (`NoteCard`, `StatusBadge`, `StateMessage`, …) and feature-only ones in that feature's `presentation/widgets/` (`LiveWaveform`, `ProcessingStepTile`, …). Screens, and widgets that only arrange a page (such as `NoteDetailView` and `RecordingLayout`), set no colors, sizes or text styles. They place components, with `AppSpacing` tokens for the gaps between them. If a screen needs a look that no component has, add or extend a component and show it on the design preview.
- **No business logic in widgets.** Widgets show data from providers and send user actions to them: a controller method or a repository call. Deciding what happens (rules, status changes, saving, retrying, timing) belongs in controllers, repositories and services.
- **Thin screens.** A screen reads providers, lays out components and forwards user actions. It imports only domain models, providers and widgets, never packages such as `record`, `just_audio`, Drift or the API client. Replacing a screen's layout must need no change outside `presentation/`.
- **Existing code:** Step 3 mostly follows these rules. Two layout widgets still set text styles directly: `ProcessingView` (title, metadata and hint) and `NoteDetailView` (summary). Move that styling into components when a step next changes those files.

## Scale goals

Design with these in mind, but only build what a step asks for. `docs/backend-plan.md` has the details.

- **About 1,000 users in the first year.** Keep the backend stateless: no in-memory state that matters, so any server instance can handle any request.
- **AI usage is the main bottleneck.** All users share the same Groq and Gemini limits and bills. Every AI call goes through the backend so it can be measured, rate-limited and retried.
- **Background jobs (Step 7b).**
  - Audio goes to Serverpod Cloud's storage, and a future call transcribes and summarizes it.
  - The app follows along through a stream.
  - The transcribe and summarize logic stays out of the endpoints, so it can later run on separate worker servers (API servers with `futureCall.executionEnabled: false`).
- **Accounts (Step 7a).** Serverpod's auth module from the first deploy. No shared app secret.
- **Usage limits (Step 7b).** Audio minutes are recorded per user, with daily and monthly limits per account and global caps. Plans with their own limits come later.
- **Server infrastructure.** Serverpod Cloud: Postgres for users, usage and jobs, file storage, and logs (Serverpod Insights). Error tracking and push notifications come later.

## Folder structure

```
echonote/
├── CLAUDE.md
├── README.md                  # what EchoNotes is; how to build, run and test it
├── docs/
│   ├── backend-plan.md        # the detailed Serverpod plan (Steps 7a, 7b and 8)
│   └── SUBMISSION.md          # the hackathon text: features, how it was built, AI tools used
├── .fvmrc                     # the pinned Flutter version, for FVM (kept)
├── .fvm/                      # FVM's link to that SDK on this machine (gitignored)
├── .vscode/settings.json      # points VS Code at the pinned SDK
├── .gitignore                 # root: secrets (.env files, passwords.yaml, signing keys), .fvm/,
│                              # OS and IDE clutter
├── pubspec.yaml               # (Step 7a) the pub workspace: app, client, server, packages/*
├── app/                       # Flutter app, Dart package `echonotes`
│   ├── lib/
│   │   ├── main.dart          # entry point: ProviderScope + EchoNotesApp
│   │   ├── app/               # app widget (theme), router, RiseInPage transition
│   │   ├── core/              # shared by several features
│   │   │   ├── database/      # Drift: AppDatabase, its provider, tables/ (see "Local database")
│   │   │   ├── formatting/    # durations as "04:05" and "32 min"
│   │   │   ├── theme/         # colors, text styles, spacing, radius, motion, ThemeData
│   │   │   └── widgets/       # shared components: RecordButton, NoteCard, TagChip, StatusBadge,
│   │   │                      # StateMessage, FeedbackBanner, ErrorSnackBarContent, ConfirmDialog
│   │   │                      # (Step 8: the generated client and the server address)
│   │   └── features/
│   │       └── <feature>/
│   │           ├── domain/        # models and abstract service interfaces
│   │           ├── data/          # implementations and the providers that wire them
│   │           └── presentation/  # screens, widgets, UI state
│   ├── assets/fonts/          # bundled Fraunces and Inter, with their licenses
│   ├── build.yaml             # Drift options, and where make-migrations finds the database
│   ├── drift_schemas/         # a saved snapshot of every schema version; never edit these
│   ├── integration_test/      # runs on a phone or simulator: records a few seconds for real
│   └── test/                  # mirrors lib/; shared helpers in test/helpers/
│                              # (pumpApp runs the whole app with a FakeNotesRepository and
│                              # fakes for recording, permissions, storage and playback;
│                              # inMemoryDatabase() gives a real, empty database)
│                              # test/drift/: schema and migration tests
├── client/                    # (Step 7a) `echonotes_client`, generated by Serverpod; never edited
├── packages/
│   └── echonotes_audio/       # (Step 7b) pure Dart: ADTS reader, .m4a writer, splitter
└── server/                    # the backend, Dart package `echonotes_server`. Still the Dart Frog
                               # starter until Step 7a replaces it with Serverpod: endpoints, models,
                               # future calls, config/, migrations/ (layout in docs/backend-plan.md)
```

Current features:

- **`notes`**: the models (`Note`, `KeyPoint`, `ActionItem`, `TranscriptSegment`, `NoteStatus`), the `NotesRepository` and `AudioFileStore` interfaces, and the home, processing and note detail screens. A note is made when recording starts (`startRecording`, status `recording`) and moves on to `uploading` when it stops (`finishRecording`). `notesRepositoryProvider` (in `data/`) supplies `DriftNotesRepository`. Screens read notes through `notesProvider` and `noteProvider(id)`, which are live streams. The list's notes leave out key points, action items and the transcript; `watchNote` gives the whole note. A note can be deleted with a long press on Home or the trash button on its detail screen, after a confirmation.
  - **Pretend processing:** `FakeNoteProcessing` stands in for the backend. It follows the saved notes and moves each unfinished one on a step every 2 seconds, then saves sample notes for it. So it also picks up retries, and notes left unfinished when the app closed. `noteProcessingProvider` runs it, and `EchoNotesApp` watches that provider to start it. Step 8 replaces it there with the real processing and deletes it.
  - **`FakeNotesRepository`** keeps notes in memory for tests. Notes keep their status until something changes them.
- **`recording`**: the recording screen and everything behind it. `RecordingController` runs one recording: the one-time reminder to tell people they're being recorded, microphone access, asking once to show the recording notification, a free-space check, then recording, pause, resume, stop and discard. Its phases and notices are in `recording_state.dart`. It talks only to interfaces in `domain/`:
  - `AudioRecorderService`, implemented by `RecordAudioRecorderService` (the `record` package).
    - **Format:** mono AAC at 16 kHz and 32 kbps, about 15 MB an hour.
    - **Crash safety:** it streams the audio and writes it to the file itself as ADTS frames (`adts.dart`), so the file is readable at every moment and a crash loses at most a fraction of a second.
    - **Pause** stops the package's recorder and **resume** starts a fresh one that adds to the same file. That keeps Android's call detection working after a pause.
    - **Watchdog:** it restarts the recorder when audio stops arriving without any event, as iOS does when headphones or Bluetooth connect.
    - **Microphone:** it records from the phone's own microphone, even with earbuds in.
    - **Interruptions:** calls and other apps pause the recording, and it carries on after (`AudioInterruptionMode.pauseResume`).
  - `BackgroundRecording` keeps the recording going in the background and with the screen locked. The controller follows every change of phase with it (`_followInBackground`), so it runs while recording, pauses while paused and stops from saving on, whatever caused the change.
    - **Android** (`ForegroundServiceBackgroundRecording`, through the `echonotes/recording` channel): `RecordingService.kt` is a foreground service of type microphone, started while the app is on screen.
      - Its notification shows a timer and Pause/Resume and Stop, which reach the controller through `RecordingPlugin.kt`.
      - It holds a partial wake lock only while recording.
      - When the recording stops by itself while the app can't be seen (limit, phone full), the notification says why.
      - While a recording runs, `MainActivity` keeps the Flutter engine alive after its screen closes. So swiping the app away doesn't stop the recording, and reopening it shows the same recording. With nothing recording, the engine closes with its screen as usual.
    - **iOS** (`AudioModeBackgroundRecording`): the `audio` background mode in `Info.plist` is all it needs, so this does nothing at runtime.
    - **Battery advice (Android):** only where it helps.
      - If the battery settings restrict EchoNotes ("Restricted"), the recording screen says so, with a "Battery settings" button.
      - The app remembers which recording ran when it left the screen (`RecordingPreferences`). If the phone then killed it, the next launch explains that and offers the settings (`RecordingCutOffDialog`).
  - `MicrophonePermission` (`permission_handler`), `StorageSpace` (the app's own `echonotes/device` channel, answered in `MainActivity.kt` and `AppDelegate.swift`), and `RecordingPreferences` (`shared_preferences`).
  - `RecordingLimits` (`recordingLimitsProvider`): 3 hours at most, a warning 5 minutes before, and 25 MB always left free.
  - **Recovery:** `RecordingRecovery` runs once at launch (`recordingRecoveryProvider`, started by `EchoNotesApp`). Notes left in `recording` by a crash or a killed app get their file repaired and measured, then go on to upload; ones without audio are deleted. Home says how many were saved, or, after a cut-off in the background on Android, shows the battery advice. A new recording waits for it, so it never touches a running one.
- **`playback`**: basic playback on the note detail screen: `AudioPlayback` (`JustAudioPlayback`), `NotePlayerController` and the `AudioPlayerBar`. The full player comes in Step 9.
- **`design_preview`**: the debug-only design review screen.

Routes all sit under home, so going straight to one still leaves home behind it: `/`, `/record`, `/processing/:id`, `/notes/:id` and `/design`. Tapping a finished note opens its detail; an unfinished or failed one opens its processing screen, which opens the note by itself when it's ready.

App ID: `com.jon.echonotes`, the same on both platforms (Android `applicationId` and `namespace`, iOS bundle identifier). Once the app is published it can never change: a new id is a new app in the stores.

## Local database

Drift (SQLite), defined in `app/lib/core/database/`. Only `DriftNotesRepository` reads or writes it.

- **File:** `echonotes.sqlite` in the app's Application Support folder. `drift_flutter` opens it on a background isolate, so queries never block the UI.
- **Tables:** `notes`, plus `key_points`, `action_items`, `transcript_segments` and `note_tags`. The last four are deleted along with their note (foreign keys with `ON DELETE CASCADE`, switched on when the database opens). Tags are rows, not a JSON list, so "notes tagged X" can use an index. Tag names compare ignoring case.
- **Ids** are UUID v7 strings, so they never clash with the server. Tag rows have no id: (note_id, name) is their key.
- **Audio:** only the file name is stored (`audio_file_name`, null when there's no recording). `AudioFileStore.pathOf` builds the full path at runtime, because on iOS the app's folder moves with updates. Recordings live in `recordings/` in Application Support, named after their note: `<note id>.aac`, AAC in ADTS frames.
- **Dates** are UTC ISO-8601 text, to the millisecond, so they sort correctly as text. `created_at` is when the recording started. `updated_at` changes with every change to a note or any of its parts; `watchNote` relies on that to update.
- **Status** is stored in the server's spelling (`writing_notes`), mapped in `note_rows.dart`. `recording` comes first and never reaches the server. `status` is free text, so adding a status needs no migration.
- **Writes:** a note and its parts are saved in one transaction. Deleting removes the rows first, then the audio file.
- **Debug builds** fill an empty database with the sample notes. Deleting every note and restarting brings them back.
- **Full-text search,** if Step 10 ("Ask your notes") searches on the phone: add an FTS5 table in a new schema version and fill it from the existing notes. Key it by `note_id`, not SQLite's hidden rowid (VACUUM can renumber it), and update it inside the repository's write transactions. The bundled SQLite already includes FTS5.

### Changing the database schema

Every app update must keep users' notes, so a released table never changes without a migration.

1. Change the table in `core/database/tables/` and add 1 to `schemaVersion` in `app_database.dart`.
2. Run `fvm dart run build_runner build`, then `fvm dart run drift_dev make-migrations`. That saves `drift_schemas/app_database/drift_schema_vN.json`, generates `app_database.steps.dart`, and writes migration tests in `test/drift/app_database/`.
3. In `onUpgrade`, after the downgrade check, run the generated steps: `await stepByStep(from1To2: (m, schema) async {...})(migrator, from, to);`.
4. Complete the generated data test for the new step, then run `fvm flutter test`.

Never edit or regenerate a saved `drift_schema_vN.json`: each one is the exact schema on real phones. `test/drift/app_database/schema_test.dart` fails when the tables and the latest snapshot disagree.

## How to work on this project

Follow this in every step. Work like a senior engineer.

- **Hackathon first.** Check every step against "Hackathon alignment". The judged path comes first, and nothing a judge or the demo can see may pretend.
- **Always use FVM.** Run every Flutter and Dart command through FVM, in every package: `fvm flutter …` and `fvm dart …`, never plain `flutter` or `dart`.
  - **The Serverpod CLI too:** run it as `fvm exec serverpod …`, so it finds the pinned Flutter and Dart.
  - **The pin:** `.fvmrc` at the repository root pins the SDK (Flutter 3.47.5 with Dart 3.13.4).
  - **The Mac's global Flutter** is a different version that other projects need, so don't upgrade or change it.
  - **To move to a new SDK,** change these together:
    - `.fvmrc`
    - the SDK constraints in every pubspec (Serverpod Cloud follows the server's)
    - `.vscode/settings.json`
    - the versions in this file
- **Plan first.** Before coding, give a short plan: what changes, which files, and any risks. Wait for an OK before anything big, such as adding packages, building a feature, or changing many files.
- **Explain choices.** When there is more than one good approach, explain the trade-offs in simple terms and recommend one.
- **Handle the unhappy paths.** Errors, no internet, permission denied, empty states, slow networks, and the app being closed in the middle of a task. Never lose a user's recording.
- **Keep it simple.** Build only what the current step needs, but never make a choice that blocks the scale goals.
- **Security first.** No secrets in the app (see Coding rules), and the server validates all input.
- **Test what matters.** Unit tests for important logic: services, repositories and parsing AI responses. Widget tests for key screens.
- **Code quality.** Strict lint rules, `flutter analyze` and `dart analyze` with every warning fixed, clear names, small files, no copy-pasted code. The target lint set everywhere is `very_good_analysis` (version 11 supports our Dart 3.13). The Serverpod server and `packages/` start on it in Step 7a, with generated code excluded. The app stays on `flutter_lints` until Later item 10.
- **Check the docs.** If unsure how a package works or whether its API has changed, check the official docs instead of guessing.
- **Review, then report.** When a step is done, review your own work like a code reviewer. Then report: what you built, how to test it, and anything you're unsure about or that needs attention later.
- **Git.** The user runs every git and GitHub command.
  - **Never** run `git` or `gh`, install `gh`, or create a repository.
  - **Keep `.gitignore` correct.**
  - **Before a step ends,** check that no secrets would be committed: `passwords.yaml`, `.env` files, API keys, signing keys and keystores, service-account files.
  - **At the end of each step,** say it's a good moment to commit, and suggest a short commit message.

## Coding rules

- **Feature-first folders.** New code goes in `features/<feature>/{domain,data,presentation}`. Only code shared by several features goes in `core/`. `domain/` never imports from `data/` or `presentation/`.
- **Small widgets, one per file.** Each widget class gets its own file, named after the class (`NoteCard` → `note_card.dart`). When a `build` method grows, extract a widget instead of a helper method that returns widgets.
- **Services behind abstract interfaces.** Every external dependency (AI vendors, speech recognizer, backend API, storage) is an `abstract interface class` in `domain/`, for example `TranscriptionService` or `NotesService`. Name each implementation after what it wraps: `GroqTranscriptionService`, `GeminiNotesService`. Callers only use the interface, so switching vendors means adding one implementation and changing one line of wiring:
  - App: a Riverpod provider typed as the interface (`Provider<NotesService>`) chooses the implementation. Tests override that provider with a fake.
    - The generated Serverpod client is used only in `data/`, inside implementations such as `ServerpodNoteProcessingService`. They turn its types into our domain models.
    - A guard test fails if `package:echonotes_client` is imported anywhere else.
  - Server: `server.dart` creates the implementations at startup. Endpoints and future calls reach them through one small services object, and tests swap fakes in there.
- **No secrets in the app.** No API keys in app code, assets or config.
  - The app only talks to our backend, signed in with the user's account.
  - The Groq and Gemini keys live only on the server.
  - The server address is passed at build time. It isn't a secret.
- **Server secrets** live in `server/config/passwords.yaml`, which git ignores; `passwords.example.yaml` lists their names. On Serverpod Cloud they live in its password store (`serverpod cloud password set`). Never log secrets or return them in responses.
- **Thin endpoints.** An endpoint method checks the caller and the input, calls a service and returns the result. Logic lives in services and future calls. Every endpoint requires sign-in.
- **Generated code is never edited by hand:** the server's `lib/src/generated/`, `client/`, and Drift's `.g.dart` files. Change the models and run the generator.
- **Imports.** Use `package:` imports (`package:echonotes/...`, `package:echonotes_server/...`).
- **Small phones and large text:** `test/app/small_screen_test.dart` opens every screen on a 320 × 568 phone with text at 200%, and any overflow fails. Add new screens there.
- **Widget test gotchas:** reading a repository stream directly in `testWidgets` hangs, so wrap it in `tester.runAsync`. Screens with a running timer (recording, spinners) never settle, so pump set durations instead of `pumpAndSettle`, or turn on `useReducedMotion`. `pumpApp` leaves notes at their status unless you pass `processingStep`. Its fake recorder records 100 ms of pretend audio every 100 ms, the microphone is allowed, and the consent reminder and the notification question count as done; pass your own fakes to change that (`FakeBackgroundRecording` stands in for Android's service, and `recovered` sets what launch recovery finds). Controller tests that use `AppLifecycleListener` step through the states one at a time (inactive, then hidden), because the test binding doesn't. To test on the real database, override `appDatabaseProvider` with `inMemoryDatabase()` (see `app_test.dart`); it closes its streams at once, so no timer is left pending.
- **SQLite in tests:** `flutter test` and the phones use the same SQLite: the `sqlite3` package's build hooks download a prebuilt copy at the first build (SQLite 3.53, FTS5 included). Nothing needs installing on the computer, but that first build needs the internet.
- **Before finishing a change:** `fvm flutter analyze` and `fvm flutter test` pass in `app/`, and `fvm dart analyze` and `fvm dart test` pass in `server/` and in each package under `packages/`.

## Open risks

- Speech recognizers that open the microphone themselves put the recording at risk, so the live preview never uses one. On iOS, the `speech_to_text` package switches the shared audio session off each time it stops listening, which stops the recorder, and it turns on Bluetooth headset microphones, which the recorder avoids. Its sessions end after about a minute on iOS and after a few seconds of silence on Android, so that would happen often. On Android 10 and later, usually only one app hears the microphone at a time, and the other gets silence. Android's `EXTRA_AUDIO_SOURCE` (Android 13) doesn't avoid that: a recognizer that doesn't support it opens the microphone instead, without saying so.
- The live preview's recognizers are new. ML Kit speech recognition is in alpha, doesn't run on phones with an unlocked bootloader, and doesn't say how long a session can last. `SpeechTranscriber` is reported missing on A13 iPhones (iPhone 11, SE 2nd gen) and covers fewer languages than Whisper. Sources disagree on whether it needs the speech recognition permission, which would add a second prompt. The device check in "Later" answers these before Step 6 starts.
- The preview's AAC-to-PCM decoder will be our own native code inside the app, so a crash there would stop the recording. Keep it small, turn every error into "preview unavailable" without touching the recording, and skip preview frames when the recognizer falls behind, so memory can't grow.
- On iOS, `record`'s stream mode stops silently when headphones or Bluetooth connect or disconnect. The watchdog restarts it after about 3 seconds, so a short gap is lost. Check how long on a real iPhone.
- On Android 10 and later, another app can take the microphone without any event: the recording carries on, but only silence arrives. The "We can't hear anything" notice appears after about 5 seconds of digital silence.
- Groq Whisper doesn't take `.aac` files, and Serverpod Cloud can't run ffmpeg. Our own Dart writer (`packages/echonotes_audio`) repackages the ADTS frames as `.m4a` without re-encoding. Check it with `ffprobe` and one real Groq call early in Step 7b.
- Finding quiet moments from AAC frame sizes (where long recordings are cut) is unproven, especially on iOS. The app's level readings are the fallback (see `docs/backend-plan.md`).
- Serverpod 4 and Serverpod Cloud came out on 14 September 2026, so expect rough edges. Two Cloud details to check with a test deploy in Step 7a:
  - whether it accepts our folder names (`server/` and `client/` rather than `*_server` and `*_client`)
  - whether its Dart 3.13 is at least 3.13.4
- Endpoint calls carry binary data as base64, about a third larger. An hour of audio is 15 MB but about 20 MB to upload. A raw-bytes upload route is the fallback if that hurts on slow networks.
- On iOS, after a phone call while the phone is locked, iOS sometimes won't restart the microphone until the app is opened (reported on Apple's developer forums, unanswered by Apple). The recording then stays paused and safe, and the banner explains when the app is opened. The Live Activity ("Later") would show it sooner.
- Some Android brands (Samsung, Xiaomi, Huawei and others) kill background apps even with a foreground service. The app can't prevent that: recovery keeps what was recorded, and the battery advice explains what to change.

## Later

Follow-ups for the step they belong to.

1. **Clean up leftover audio files.** A background cleanup that finds files in `recordings/` with no matching note and deletes them. Leftovers happen when a note is deleted but its file can't be (the delete is logged).
2. **Let "Try again" reopen the database** (polish step). If the database can't open at launch, for example because the disk is full, Home shows "Couldn't load your notes". "Try again" then retries the same failed connection, which `appDatabaseProvider` makes only once, so only restarting the app helps. Retrying should open the database again.
3. **Keep the server's ids for a note's parts** (sync step). `saveNote` gives key points, action items and transcript segments new ids on every save. That's fine while they're written only once, but sync needs the same id on the phone and the server, so keep the ids the server sends. The server gives every part an id from Step 7b on. `KeyPoint` and `TranscriptSegment` will need an `id` field for that.
4. **A separate type for the notes list** (redesign, after Step 8). `watchNotes()` returns `Note` objects without key points, action items or transcript, so a list note looks whole but isn't. A `NoteSummary` type for the list would make that mistake impossible.
5. **Check seeking on iOS** (Step 9). Seeking in an ADTS file is estimated from the bitrate. Check that it's precise on iOS. If it isn't, repackage the recording as `.m4a` when recording ends, with the writer in `packages/echonotes_audio`. Quiet stretches encode smaller than speech, so estimates can be well off: macOS estimated an 8 min 22 s emulator recording, all silence, at 7 min 21 s.
6. **An iOS Live Activity** (polish). The recording's timer on the lock screen and in the Dynamic Island, with Pause and Stop. It also shows when iOS paused the recording for a call and won't let it carry on by itself.
7. **Store declarations for background recording** (launch step).
    - **Google Play:** in the Play Console, declare the foreground service of type microphone: what it does and why it's needed. Google may ask for a short video of it in use.
    - **App Review:** add notes for Apple that explain why EchoNotes records in the background (the `audio` background mode): to keep a meeting or lecture recording going while the phone is locked, as the user started it.
8. **Check the live preview's recognizers on real phones** (before Step 6). A one-day check before building the preview:
    - ML Kit speech recognition with our own audio (decoded from a real recording) for 60+ minutes, on a Pixel and on a Samsung: does the session keep going, and how far behind does the text fall?
    - `SpeechTranscriber` on an iPhone with real meeting audio at our 32 kbps quality.
    - Battery use over an hour with the preview on.
    - Whether iOS asks for the speech recognition permission.
    - That ML Kit builds with our Android tools (AGP 9.1, Kotlin 2.4, with `android.builtInKotlin=false`), and which minimum Android version it needs.
9. **A fallback preview from Groq** (decide after Step 7b). For phones the system recognizers don't cover (iOS before 26, Android before 12, languages they don't support), the preview could come from the backend: send 20–30 s chunks to Groq Whisper while recording.
    - The text arrives 25–35 s late, and offline it pauses and catches up later.
    - Each recording makes 2–3 Groq requests a minute instead of about one in all, and Groq's free tier allows 20 a minute for the whole app. Unless the chunks are reused as the final transcript, those recordings are also transcribed twice.
    - Chunks cut on ADTS frame boundaries at quiet moments, with a little overlap, could reuse the splitter in `packages/echonotes_audio`.
10. **Move the app to `very_good_analysis`** (cleanup step). Replace `flutter_lints` in `app/` and fix what it finds, so the app and the server use the same lint set.
11. **Move the app onto the shared audio package** (cleanup step). Step 7b creates `packages/echonotes_audio` (ADTS reader, `.m4a` writer, splitter) for the server. Move the app's own ADTS parsing in `adts.dart` onto it, so a fix reaches both. The recorder's frame writing is crash-safety code, so leave it alone unless the package covers it.
12. **Turn on AGP 9's built-in Kotlin and new DSL** (when Flutter's template does). Both are `false` in `android/gradle.properties`, as in Flutter 3.47's own template, and Flutter's Gradle plugin applies Kotlin itself. Flutter plans to drop that support. Once Flutter and every plugin support built-in Kotlin, follow Flutter's guide "Migrating Flutter Android projects to built-in Kotlin".
13. **Tell the user when a note is ready** (after the hackathon). Send a push notification (FCM and APNs) when a job finishes while the app is closed.
14. **Google and Apple sign-in** (after the hackathon). The auth module supports both. They need Google Cloud and Apple developer setup.
15. **Delete your account in the app** (launch step). Google Play and the App Store require it for apps where people create accounts. It deletes the account and its jobs, audio and notes on the server.
16. **Redis for live status across servers** (once we run more than one server). Without Redis, `jobs.watch()` re-reads the database every few seconds. With it, server events reach every server at once. Serverpod Cloud doesn't provide Redis; its docs suggest Upstash.
17. **A raw-bytes upload route** (if uploads prove too slow). Endpoint calls carry chunks as base64, about a third larger. A route that takes the raw bytes removes that overhead, but must handle sign-in and limits by hand.
18. **Paid Groq before launch** (launch step). Groq's free tier caps all users together at 8 hours of audio a day and 25 MB per file. Move to its Dev tier and check that Zero Data Retention is on. (Gemini's paid tier comes earlier, before judges get access: see "Hackathon alignment".)

## Commands

Everything runs through FVM (see "How to work on this project").

```bash
# First time on a machine (from the repository root)
brew install fvm
fvm install                                               # the Flutter pinned in .fvmrc

# App (run from app/)
fvm flutter pub get
fvm flutter run                                           # choose a simulator, emulator or device
fvm dart run build_runner build                           # regenerate Drift code
fvm dart run drift_dev make-migrations                    # after a schema change, see "Changing the database schema"
fvm flutter analyze && fvm flutter test
fvm flutter test integration_test -d <device>             # records for real; allow the microphone first

# Server (run from server/). Until Step 7a it's the Dart Frog starter: `fvm dart test` is all it has.
# From Step 7a, Serverpod (the CLI install and the exact commands get confirmed in that step):
fvm exec serverpod start --no-flutter                     # server and embedded Postgres, with hot reload
fvm exec serverpod generate                               # after changing models or endpoints
fvm exec serverpod create-migration                       # after changing a table
fvm dart analyze && fvm dart test
fvm exec serverpod cloud deploy                           # deploy to Serverpod Cloud
```
