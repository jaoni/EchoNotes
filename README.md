# EchoNotes

Record a meeting, lecture or interview on your phone, and get organized notes back: a title, a short summary, key points, action items and tags, written in the language that was spoken.

EchoNotes is a Flutter app for Android and iOS with a [Serverpod](https://serverpod.dev) backend, built for "Build Something Real: The Serverpod Hackathon".

> **Status, 3 October 2026:** the app records for real, in the background and with the screen locked, and saves notes on the phone. The Serverpod backend that transcribes and summarizes is being built now (see [docs/backend-plan.md](docs/backend-plan.md)). Until the app is connected to it, a recording ends with clearly labelled sample notes. This README is updated as each part lands.

## How it works

1. **Record.** One tap starts a recording. It keeps going in the background and with the screen locked. It survives calls and crashes, and it's saved on the phone as it's made.
2. **Upload** *(in progress)*. When you stop, the app uploads the audio to the Serverpod backend in small resumable chunks.
3. **Transcribe** *(in progress)*. A Serverpod future call sends the audio to Groq Whisper for a timestamped transcript.
4. **Summarize** *(in progress)*. Google Gemini turns the transcript into structured notes.
5. **Read and listen.** The note appears on the phone, next to the recording.

## Repository layout

| Folder | What it holds |
|---|---|
| `app/` | The Flutter app |
| `server/` | The backend. It's being rebuilt on Serverpod; today it's still a starter project. |
| `docs/` | The backend plan and the hackathon submission text |
| `CLAUDE.md` | The project's design and working rules, which also guide Claude Code |

## Build and run the app

You need [FVM](https://fvm.app), which installs the exact Flutter this project pins (Flutter 3.47.5 with Dart 3.13.4). You also need:
- **For Android:** the Android SDK.
- **For iOS:** a Mac with Xcode, and your own signing team selected in Xcode.

```bash
brew install fvm          # or see fvm.app for other systems
fvm install               # run from the repository root: installs the pinned Flutter

cd app
fvm flutter pub get
fvm flutter run           # pick an emulator, simulator or phone
```

The first build downloads a prebuilt SQLite, so it needs the internet.

## Tests

```bash
cd app
fvm flutter analyze && fvm flutter test
fvm flutter test integration_test -d <device>   # records for real: allow the microphone first
```

## Run the backend

Coming with the move to Serverpod (Step 7a). This section will cover running the server locally with Serverpod's embedded Postgres. No Docker will be needed.

## Try it as a judge

Coming with the release: a link to the Android build, and a test account in the submission form.
