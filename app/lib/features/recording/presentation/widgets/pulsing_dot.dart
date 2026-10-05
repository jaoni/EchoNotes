import 'package:material_ui/material_ui.dart';

/// A small dot that slowly fades in and out while [isPulsing], like a
/// recorder's "on air" light. With less motion, it stays still.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.isPulsing, required this.color});

  final bool isPulsing;
  final Color color;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  static const _size = 10.0;
  static const _period = Duration(milliseconds: 1200);
  static const _dimmest = 0.3;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: _period,
  );
  late final Animation<double> _opacity = _pulse.drive(
    Tween<double>(
      begin: 1,
      end: _dimmest,
    ).chain(CurveTween(curve: Curves.easeInOut)),
  );

  bool get _shouldPulse =>
      widget.isPulsing && !MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(PulsingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _syncPulse() {
    if (_shouldPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!_shouldPulse && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SizedBox.square(
        dimension: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
