import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_motion.dart';
import 'package:echonotes/core/theme/app_radius.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/core/widgets/record_ripple_painter.dart';

/// The big record button: an accent disc with a mic, inside a thin ink ring.
///
/// The caller owns the recording state and passes it in. While [isRecording],
/// the disc morphs into a stop square and soft rings spread out, reaching
/// further as [level] rises. While [isPaused], the stop square stays but the
/// rings rest. When the user asks for less motion, the rings stay still.
class RecordButton extends StatefulWidget {
  const RecordButton({
    super.key,
    required this.isRecording,
    required this.onPressed,
    this.isPaused = false,
    this.level = 0,
  });

  /// Diameter of the tappable button, not counting the ripples around it.
  static const double size = 88;

  /// How far the ripples reach beyond the button.
  static const double rippleSpread = 24;

  /// The whole square the widget takes up, ripples included. Leave this much
  /// room when the button floats over other content.
  static const double footprint = size + 2 * rippleSpread;

  final bool isRecording;

  /// Only matters while [isRecording]: the recording can still be stopped,
  /// but nothing is being heard.
  final bool isPaused;

  /// Null disables the button, for example while mic permission is missing.
  final VoidCallback? onPressed;

  /// Voice loudness from 0 (silence) to 1 (loud).
  final double level;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  static const _discSize = 72.0;
  static const _stopSize = 32.0;
  static const _iconSize = 32.0;
  static const _ringWidth = 2.0;
  static const _ripplePeriod = Duration(milliseconds: 1600);
  static const _stillRipple = AlwaysStoppedAnimation<double>(0.6);

  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: _ripplePeriod,
  );

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  bool get _showsRipples => widget.isRecording && !widget.isPaused;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRipple();
  }

  @override
  void didUpdateWidget(RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRipple();
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  void _syncRipple() {
    final shouldAnimate = _showsRipples && !_reduceMotion;
    if (shouldAnimate && !_ripple.isAnimating) {
      _ripple.repeat();
    } else if (!shouldAnimate && _ripple.isAnimating) {
      _ripple.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduceMotion = _reduceMotion;
    final isRecording = widget.isRecording;
    final isEnabled = widget.onPressed != null;
    final duration = reduceMotion ? Duration.zero : AppMotion.medium;
    final innerSize = isRecording ? _stopSize : _discSize;

    return Semantics(
      container: true,
      button: true,
      enabled: isEnabled,
      label: isRecording ? 'Stop recording' : 'Start recording',
      child: SizedBox.square(
        dimension: RecordButton.footprint,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The ripples are decoration: taps pass through to what's behind.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _showsRipples ? 1 : 0,
                  duration: duration,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: widget.level.clamp(0, 1)),
                    duration: AppMotion.fast,
                    builder: (context, level, _) => CustomPaint(
                      painter: RecordRipplePainter(
                        progress: reduceMotion ? _stillRipple : _ripple,
                        level: reduceMotion ? 0 : level,
                        color: colors.accent,
                        startRadius: RecordButton.size / 2,
                        maxSpread: RecordButton.rippleSpread,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: widget.onPressed,
                customBorder: const CircleBorder(),
                child: Container(
                  width: RecordButton.size,
                  height: RecordButton.size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isEnabled ? colors.textPrimary : colors.border,
                      width: _ringWidth,
                    ),
                  ),
                  child: AnimatedContainer(
                    duration: duration,
                    curve: AppMotion.emphasized,
                    width: innerSize,
                    height: innerSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isEnabled ? colors.accent : colors.muted,
                      borderRadius: BorderRadius.circular(
                        isRecording ? AppRadius.sm : _discSize / 2,
                      ),
                    ),
                    child: AnimatedOpacity(
                      opacity: isRecording ? 0 : 1,
                      duration: duration,
                      child: Icon(
                        Icons.mic_rounded,
                        size: _iconSize,
                        color: isEnabled
                            ? colors.onAccent
                            : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
