import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Material and Cupertino come from the `material_ui` and `cupertino_ui`
/// packages. Flutter still ships its own copies, with the same class names,
/// and editors offer both when adding an import. A widget built from
/// Flutter's copy doesn't see the app's theme, and go_router doesn't
/// recognise an app built from it, so screens open without transitions.
/// Nothing fails when that happens, so this test does.
void main() {
  test("no code imports Flutter's own Material or Cupertino", () {
    final flutterCopy = RegExp(
      r"^import 'package:flutter/(material|cupertino)\.dart'",
      multiLine: true,
    );
    final offenders = [
      for (final folder in ['lib', 'test', 'integration_test'])
        for (final entity in Directory(folder).listSync(recursive: true))
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              flutterCopy.hasMatch(entity.readAsStringSync()))
            entity.path,
    ];

    expect(
      offenders,
      isEmpty,
      reason:
          'Import package:material_ui/material_ui.dart and '
          'package:cupertino_ui/cupertino_ui.dart instead.',
    );
  });
}
