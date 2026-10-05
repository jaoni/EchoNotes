import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';
import 'package:echonotes/features/recording/presentation/widgets/waveform_painter.dart';

/// The voice level over the last few seconds, scrolling in from the right.
/// Dims while paused. With less motion, it rests as a still line of dots.
class LiveWaveform extends ConsumerWidget {
  const LiveWaveform({super.key});

  static const _height = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final levels = ref.watch(
      recordingControllerProvider.select((state) => state.levels),
    );
    final isRecording = ref.watch(
      recordingControllerProvider.select(
        (state) => state.phase == RecordingPhase.recording,
      ),
    );
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Decoration only: the status label and timer already say what's
    // happening.
    return ExcludeSemantics(
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: CustomPaint(
          painter: WaveformPainter(
            levels: reduceMotion ? const [] : levels,
            color: isRecording ? colors.accent : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
