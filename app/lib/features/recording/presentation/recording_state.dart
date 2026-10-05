/// Where the recording screen is, from opening to leaving.
enum RecordingPhase {
  /// Getting ready: checking access and space, and making the note.
  preparing,

  /// The one-time reminder to tell people they're being recorded.
  reminder,

  /// Microphone access was refused. The app can ask again.
  permissionDenied,

  /// Microphone access is off, and only the phone's settings can turn it
  /// on.
  permissionBlocked,

  /// Too little free space to record.
  notEnoughSpace,

  /// The microphone wouldn't start, for example because another app has
  /// it.
  couldNotStart,

  recording,
  paused,

  /// Stopping and saving.
  saving,

  /// Saved as the note [RecordingState.noteId], which goes on to
  /// processing.
  stopped,

  /// Thrown away, with its note and audio.
  discarded;

  /// Something has been recorded, so leaving takes care.
  bool get hasAudio => this == recording || this == paused || this == saving;
}

/// Something the user should know while recording, most important first:
/// only the first one that applies is shown.
enum RecordingNotice {
  /// Saving failed. The recording is paused and safe.
  saveFailed,

  /// Resuming failed, for example because a call still has the
  /// microphone.
  resumeFailed,

  /// The phone paused the recording, for a call or another app.
  interrupted,

  /// Only silence arrives, as when another app has the microphone.
  noSound,

  /// The phone may stop the recording if the app is left: its battery
  /// settings limit EchoNotes in the background, or it wouldn't start the
  /// background service.
  limitedInBackground,

  /// The recording is close to its maximum length.
  limitSoon,

  /// The phone has room for less than a recording of maximum length.
  lowSpace,
}

/// Why a recording stopped.
enum RecordingEnding {
  byUser,

  /// It reached its maximum length.
  limitReached,

  /// The phone ran out of space.
  outOfSpace,

  /// The file couldn't be written.
  fileError,
}

/// Everything the recording screen shows.
class RecordingState {
  const RecordingState({
    this.phase = RecordingPhase.preparing,
    this.elapsed = Duration.zero,
    this.levels = const [],
    this.transcript = '',
    this.notices = const {},
    this.noteId,
    this.spaceLeft,
    this.ending,
  });

  final RecordingPhase phase;

  /// How much has been recorded, not counting pauses.
  final Duration elapsed;

  /// Recent voice levels from 0 to 1, oldest first. Drawn as the waveform.
  final List<double> levels;

  /// A rough live preview of what's being said, from the phone's speech
  /// recognizer. Empty until the live preview arrives (Step 6).
  final String transcript;

  final Set<RecordingNotice> notices;

  /// The recording's note, from the moment recording starts.
  final String? noteId;

  /// About how long the phone has room to record, when it's less than the
  /// maximum length.
  final Duration? spaceLeft;

  /// Why the recording stopped, once it has.
  final RecordingEnding? ending;

  /// Paused, with the recorder ready to carry on. After saving failed the
  /// recorder has already stopped, so only stopping (to save again) or
  /// discarding is left.
  bool get canResume {
    return phase == RecordingPhase.paused &&
        !notices.contains(RecordingNotice.saveFailed);
  }

  /// The notice to show, if any.
  RecordingNotice? get notice {
    for (final notice in RecordingNotice.values) {
      if (notices.contains(notice)) return notice;
    }
    return null;
  }

  RecordingState copyWith({
    RecordingPhase? phase,
    Duration? elapsed,
    List<double>? levels,
    Set<RecordingNotice>? notices,
    String? noteId,
    Duration? spaceLeft,
    RecordingEnding? ending,
  }) {
    return RecordingState(
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      levels: levels ?? this.levels,
      transcript: transcript,
      notices: notices ?? this.notices,
      noteId: noteId ?? this.noteId,
      spaceLeft: spaceLeft ?? this.spaceLeft,
      ending: ending ?? this.ending,
    );
  }

  /// With [add] shown and [remove] gone.
  RecordingState withNotices({
    Set<RecordingNotice> add = const {},
    Set<RecordingNotice> remove = const {},
  }) {
    return copyWith(notices: {...notices.difference(remove), ...add});
  }
}
