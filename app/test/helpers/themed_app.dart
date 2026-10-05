import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_theme.dart';

/// A [MaterialApp] with the app's light theme around [home], for widget tests.
Widget themedApp(Widget home, {bool reduceMotion = false}) {
  return MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: child!,
    ),
    home: home,
  );
}

/// Like [themedApp], with [child] centred on a plain screen.
Widget themedComponent(Widget child, {bool reduceMotion = false}) {
  return themedApp(
    Scaffold(body: Center(child: child)),
    reduceMotion: reduceMotion,
  );
}
