import 'package:flutter/animation.dart';

/// Animation durations and curves. Motion stays calm: short, eased, no bounce.
///
/// Check `MediaQuery.disableAnimationsOf(context)` and swap looping motion for
/// a still state when the user asks for less motion.
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 150);
  static const medium = Duration(milliseconds: 250);

  /// For a whole screen coming in, such as the recording screen.
  static const slow = Duration(milliseconds: 400);

  /// For things that appear or change shape.
  static const Curve emphasized = Curves.easeOutCubic;
}
