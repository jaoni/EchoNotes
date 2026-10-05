import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';
import 'package:echonotes/features/recording/presentation/widgets/pulsing_dot.dart';

/// "Recording", "Paused", "Saving…" and so on, with a dot that pulses while
/// the microphone is on.
class RecordingStatusLabel extends ConsumerWidget {
  const RecordingStatusLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final phase = ref.watch(
      recordingControllerProvider.select((state) => state.phase),
    );
    final isRecording = phase == RecordingPhase.recording;

    return Semantics(
      liveRegion: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulsingDot(
            isPulsing: isRecording,
            color: isRecording ? colors.accent : colors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(switch (phase) {
              RecordingPhase.preparing => 'Starting…',
              RecordingPhase.recording => 'Recording',
              RecordingPhase.paused => 'Paused',
              RecordingPhase.saving => 'Saving…',
              RecordingPhase.stopped => 'Saved',
              RecordingPhase.discarded => 'Discarded',
              RecordingPhase.reminder ||
              RecordingPhase.permissionDenied ||
              RecordingPhase.permissionBlocked ||
              RecordingPhase.notEnoughSpace ||
              RecordingPhase.couldNotStart => 'Not recording',
            }, style: context.textTheme.labelLarge),
          ),
        ],
      ),
    );
  }
}
