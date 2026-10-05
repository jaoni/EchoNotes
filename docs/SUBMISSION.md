# EchoNotes: submission text

> **Draft.** This file grows with the project. It separates what's built from what's in progress, and the final version is due by 14 October 2026.

## The problem, and who it's for

In a meeting, a lecture or an interview, you can either listen or take notes, and doing both well is hard. EchoNotes is for people who would rather listen. They tap record, and afterwards they get organized notes:
- a title
- a short summary
- the key points
- the action items, to tick off
- a few tags

The notes are written in the language that was spoken, next to the recording itself.

## What it does

**Built so far:**

- **Recording you can trust.**
  - One tap starts a recording, and it keeps going in the background and with the screen locked.
  - On Android, a notification shows the timer and lets you pause, resume or stop.
  - Phone calls pause the recording, and it carries on afterwards.
- **Nothing is lost.**
  - The audio is written to the phone as it's recorded, so a crash or a killed app loses at most a fraction of a second.
  - The next launch repairs the file and saves the note.
  - The app warns when the phone has less room than a full-length recording needs.
  - It stops safely at the 3-hour limit (with a warning 5 minutes before) or before the phone is full, and says why.
- **Notes on the phone.** Notes live in a local database, with tags and playback. Long-press or tap the bin to delete a note, after a confirmation.
- **A calm design** ("Paper & Ink"):
  - warm paper backgrounds, ink-dark text, and one accent that marks recording
  - a dark mode
  - layouts that hold up on small phones and at 200% text size

**In progress:**

- **The Serverpod backend:** sign-in with email, resumable uploads, and the background pipeline that turns a recording into a transcript and notes.
- **Live status:** each stage appears as it happens (uploading, transcribing, writing notes, ready).

## How it was built

- **The app:**
  - Flutter 3.47 for Android and iOS
  - Riverpod for state, go_router for navigation, and Drift (SQLite) for the local database
  - `record` for audio, and `just_audio` for playback
- **The backend (in progress):** Serverpod 4, hosted on Serverpod Cloud. Serverpod does the real work:
  - **Typed endpoints** for the app.
  - **The auth module:** email sign-in, with codes sent by Serverpod Cloud.
  - **Resumable uploads:** chunks of about 1 MB that pick up where they stopped.
  - **Future calls** for the processing pipeline. A crashed server's work is taken over by another.
  - **A streaming endpoint** for live job status.
  - **Postgres and file storage** from Serverpod Cloud.
- **AI, called only from the server:** Groq Whisper (`whisper-large-v3-turbo`) transcribes, and Google Gemini writes the notes.
  - A shared rate limiter in Postgres keeps every user together within the providers' limits.
  - Per-account limits protect the shared quota.
- **Audio in pure Dart:** our own code reads the recorder's AAC frames, repackages them as `.m4a` and splits long recordings at quiet moments. So the server needs no ffmpeg.

### Engineering notes

- Recording streams AAC frames to disk itself, so the file is valid at every moment.
- On Android, a foreground service of type microphone keeps recording going, and its notification controls go back to the app's controller. iOS uses its audio background mode.
- More than 240 unit and widget tests, plus device tests that record for real on Android and iOS.
- Guard tests catch mistakes that compile but look wrong. One checks every screen on a small phone with large text, and another catches Material imports that would silently lose the theme.

## AI tools used

- **Claude Code** (Anthropic's coding agent), running **Claude Opus 5.5** in every session. It planned each step, wrote the code and tests, checked documentation, and reviewed its own work.
- **The developer** set the goals, approved every plan before any code was written, and decided each trade-off.
- **In the product:** Groq Whisper and Google Gemini (see above).

## Built during the hackathon

The project was started on 30 September 2026, during the submission period.
