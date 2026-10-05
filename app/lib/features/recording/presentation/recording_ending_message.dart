import 'package:echonotes/core/formatting/duration_format.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';

/// Why a recording stopped by itself, and that what was recorded is kept.
/// Shown in the app, and on Android in a notification when the app can't
/// be seen. Null when the user stopped it.
String? recordingEndingMessage(RecordingEnding ending, Duration maxLength) {
  return switch (ending) {
    RecordingEnding.byUser => null,
    RecordingEnding.limitReached =>
      'The recording reached its ${formatLength(maxLength)} limit, so it '
          'stopped and was saved.',
    RecordingEnding.outOfSpace =>
      'Your phone ran out of space, so the recording stopped. What was '
          'recorded is saved.',
    RecordingEnding.fileError =>
      "The recording stopped because it couldn't be saved on this phone. "
          'What was recorded so far is kept.',
  };
}
