import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/core/widgets/record_button.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/preview_section.dart';

/// The record button with a pretend recording: a ticking timer and a fake
/// voice level, so the animation can be reviewed without the microphone.
class RecordButtonDemo extends StatefulWidget {
  const RecordButtonDemo({super.key});

  @override
  State<RecordButtonDemo> createState() => _RecordButtonDemoState();
}

class _RecordButtonDemoState extends State<RecordButtonDemo> {
  static const _tick = Duration(milliseconds: 120);

  /// How much of the previous level each tick keeps, so the fake voice rises
  /// and falls smoothly instead of flickering.
  static const _smoothing = 0.6;

  final _stopwatch = Stopwatch();
  final _random = Random();
  Timer? _ticker;
  double _level = 0;

  bool get _isRecording => _ticker != null;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      if (_isRecording) {
        _ticker?.cancel();
        _ticker = null;
        _stopwatch.stop();
        _level = 0;
      } else {
        _stopwatch
          ..reset()
          ..start();
        _ticker = Timer.periodic(_tick, (_) => setState(_nextLevel));
      }
    });
  }

  void _nextLevel() {
    _level = _level * _smoothing + _random.nextDouble() * (1 - _smoothing);
  }

  static String _formatElapsed(Duration elapsed) {
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final captionStyle = context.textTheme.bodySmall?.copyWith(
      color: colors.textSecondary,
    );

    return PreviewSection(
      title: 'Record button',
      child: Column(
        children: [
          Text(
            _formatElapsed(_stopwatch.elapsed),
            style: AppTextStyles.timer.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          RecordButton(
            isRecording: _isRecording,
            level: _level,
            onPressed: _toggle,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _isRecording
                ? 'Pretend recording. The rings follow a fake voice.'
                : 'Tap to try a pretend recording.',
            textAlign: TextAlign.center,
            style: captionStyle,
          ),
          const SizedBox(height: AppSpacing.xl),
          RecordButton(isRecording: true, isPaused: true, onPressed: () {}),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Paused: the rings rest, and stop is still one tap away.',
            textAlign: TextAlign.center,
            style: captionStyle,
          ),
          const SizedBox(height: AppSpacing.xl),
          const RecordButton(isRecording: false, onPressed: null),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Disabled, for example without mic permission.',
            textAlign: TextAlign.center,
            style: captionStyle,
          ),
        ],
      ),
    );
  }
}
