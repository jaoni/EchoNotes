import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/state_message.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';

/// Why recording can't start, and what to do about it: allow the
/// microphone, open the settings, or try again.
///
/// For [phase] [RecordingPhase.permissionDenied],
/// [RecordingPhase.permissionBlocked], [RecordingPhase.notEnoughSpace] or
/// [RecordingPhase.couldNotStart].
class RecordingProblemMessage extends StatelessWidget {
  const RecordingProblemMessage({
    super.key,
    required this.phase,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final RecordingPhase phase;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final tryAgain = FilledButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Try again'),
    );

    return switch (phase) {
      RecordingPhase.permissionDenied => StateMessage(
        icon: Icons.mic_off_outlined,
        title: 'EchoNotes needs the microphone',
        message:
            "To record your conversations, allow EchoNotes to use your "
            "phone's microphone.",
        action: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.mic_rounded),
          label: const Text('Allow microphone'),
        ),
      ),
      RecordingPhase.permissionBlocked => StateMessage(
        icon: Icons.mic_off_outlined,
        title: 'Microphone access is off',
        message:
            "Turn on the microphone for EchoNotes in your phone's settings, "
            'then come back here.',
        action: FilledButton.icon(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings_outlined),
          label: const Text('Open settings'),
        ),
      ),
      RecordingPhase.notEnoughSpace => StateMessage(
        icon: Icons.sd_storage_outlined,
        title: 'Your phone is almost full',
        message: 'Free up some space to record, then try again.',
        action: tryAgain,
        isError: true,
      ),
      _ => StateMessage(
        icon: Icons.error_outline_rounded,
        title: "Couldn't start recording",
        message:
            'Another app may be using the microphone. Close it, then try '
            'again.',
        action: tryAgain,
        isError: true,
      ),
    };
  }
}
