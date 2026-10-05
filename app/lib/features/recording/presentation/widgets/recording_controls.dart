import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/widgets/record_button.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';

/// Pause or resume on the left and the big stop button in the middle, which
/// pulses with the voice. Only what can be done now is enabled: nothing
/// while starting or saving, and no resuming after saving failed.
class RecordingControls extends ConsumerWidget {
  const RecordingControls({super.key, required this.onStop});

  static const _sideButtonSize = 56.0;
  static const _sideIconSize = 28.0;

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(recordingControllerProvider.notifier);
    final phase = ref.watch(
      recordingControllerProvider.select((state) => state.phase),
    );
    final canResume = ref.watch(
      recordingControllerProvider.select((state) => state.canResume),
    );
    final level = ref.watch(
      recordingControllerProvider.select(
        (state) => state.levels.lastOrNull ?? 0,
      ),
    );
    final isRecording = phase == RecordingPhase.recording;
    final isPaused = phase == RecordingPhase.paused;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton.filledTonal(
          tooltip: isPaused ? 'Resume' : 'Pause',
          iconSize: _sideIconSize,
          style: IconButton.styleFrom(
            minimumSize: const Size.square(_sideButtonSize),
          ),
          onPressed: switch (phase) {
            RecordingPhase.recording => controller.pause,
            RecordingPhase.paused when canResume => controller.resume,
            _ => null,
          },
          icon: Icon(isPaused ? Icons.mic_rounded : Icons.pause_rounded),
        ),
        RecordButton(
          isRecording: true,
          isPaused: !isRecording,
          level: level,
          onPressed: isRecording || isPaused ? onStop : null,
        ),
        // Balances the pause button, so the stop button stays centred.
        const SizedBox.square(dimension: _sideButtonSize),
      ],
    );
  }
}
