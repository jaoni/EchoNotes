import 'package:flutter/widgets.dart';

/// Paints the soft rings that spread out from the record button while it
/// records, like ink spreading on paper.
///
/// Each ring is a band from [startRadius] outwards that widens and fades as
/// [progress] runs from 0 to 1. Louder [level] makes the rings reach further.
class RecordRipplePainter extends CustomPainter {
  RecordRipplePainter({
    required this.progress,
    required this.level,
    required this.color,
    required this.startRadius,
    required this.maxSpread,
  }) : super(repaint: progress);

  static const _ringCount = 2;
  static const _maxOpacity = 0.28;

  /// Share of [maxSpread] the rings reach in silence, so the button still
  /// looks alive in a quiet room.
  static const _quietSpread = 0.35;

  final Animation<double> progress;

  /// Voice loudness from 0 to 1.
  final double level;
  final Color color;
  final double startRadius;
  final double maxSpread;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final spread = maxSpread * (_quietSpread + (1 - _quietSpread) * level);

    for (var i = 0; i < _ringCount; i++) {
      final t = (progress.value + i / _ringCount) % 1;
      final width = spread * t;
      if (width == 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = color.withValues(alpha: _maxOpacity * (1 - t));
      canvas.drawCircle(center, startRadius + width / 2, paint);
    }
  }

  @override
  bool shouldRepaint(RecordRipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.level != level ||
        oldDelegate.color != color ||
        oldDelegate.startRadius != startRadius ||
        oldDelegate.maxSpread != maxSpread;
  }
}
