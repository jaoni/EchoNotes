import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/core/theme/app_motion.dart';

/// A page that fades in while rising a little, for screens the user enters
/// like a mode, such as recording. With less motion, it simply appears.
class RiseInPage<T> extends CustomTransitionPage<T> {
  const RiseInPage({super.key, required super.child})
    : super(
        fullscreenDialog: true,
        transitionDuration: AppMotion.slow,
        reverseTransitionDuration: AppMotion.medium,
        transitionsBuilder: _transition,
      );

  /// How far below its place the page starts, as a share of its height.
  static const _startOffset = Offset(0, 0.06);

  static Widget _transition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    final curve = CurveTween(curve: AppMotion.emphasized);
    return FadeTransition(
      opacity: animation.drive(curve),
      child: SlideTransition(
        position: animation.drive(
          Tween(begin: _startOffset, end: Offset.zero).chain(curve),
        ),
        child: child,
      ),
    );
  }
}
