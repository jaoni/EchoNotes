import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/error_snack_bar_content.dart';
import 'package:echonotes/features/recording/presentation/recording_ending_message.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';

/// Tells the user why a recording stopped by itself, and that what was
/// recorded is saved. Problems show as errors; reaching the time limit
/// doesn't.
class RecordingEndingSnackBarContent extends StatelessWidget {
  const RecordingEndingSnackBarContent({
    super.key,
    required this.ending,
    required this.maxLength,
  });

  final RecordingEnding ending;
  final Duration maxLength;

  /// Whether stopping this way needs telling: the user didn't choose it.
  static bool isNeededFor(RecordingEnding? ending) {
    return ending != null && ending != RecordingEnding.byUser;
  }

  @override
  Widget build(BuildContext context) {
    final message =
        recordingEndingMessage(ending, maxLength) ?? 'The recording was saved.';
    return switch (ending) {
      RecordingEnding.byUser || RecordingEnding.limitReached => Text(message),
      RecordingEnding.outOfSpace ||
      RecordingEnding.fileError => ErrorSnackBarContent(message: message),
    };
  }
}
