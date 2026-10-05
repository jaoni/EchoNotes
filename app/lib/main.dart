import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/app/app.dart';
import 'package:echonotes/core/theme/font_licenses.dart';

void main() {
  registerFontLicenses();
  runApp(const ProviderScope(child: EchoNotesApp()));
}
