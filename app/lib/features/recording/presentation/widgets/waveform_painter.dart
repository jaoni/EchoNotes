import 'dart:math';

import 'package:flutter/widgets.dart';

/// Paints recent voice levels as rounded bars, newest on the right. Where
/// there are no levels yet, it paints small dots, like silence.
class WaveformPainter extends CustomPainter {
  WaveformPainter({required this.levels, required this.color});

  static const _barWidth = 4.0;
  static const _gap = 3.0;

  /// Voice levels from 0 to 1, oldest first.
  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _barWidth
      ..strokeCap = StrokeCap.round;
    final barCount = ((size.width + _gap) / (_barWidth + _gap)).floor();
    final centerY = size.height / 2;
    // Round caps add half a bar width at each end.
    final maxLineLength = max(0.0, size.height - _barWidth);

    for (var i = 0; i < barCount; i++) {
      final levelIndex = levels.length - barCount + i;
      final level = levelIndex >= 0 ? levels[levelIndex].clamp(0.0, 1.0) : 0.0;
      final halfLength = maxLineLength * level / 2;
      final x =
          size.width - _barWidth / 2 - (barCount - 1 - i) * (_barWidth + _gap);
      canvas.drawLine(
        Offset(x, centerY - halfLength),
        Offset(x, centerY + halfLength),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.levels != levels || oldDelegate.color != color;
  }
}
