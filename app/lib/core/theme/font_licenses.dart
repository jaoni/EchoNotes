import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const _fontLicenses = [
  ('Fraunces', 'assets/fonts/OFL-Fraunces.txt'),
  ('Inter', 'assets/fonts/OFL-Inter.txt'),
];

/// Adds the bundled fonts' licenses to the app's license page, as the
/// SIL Open Font License asks. The files load only when that page opens.
void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (family, path) in _fontLicenses) {
      final text = await rootBundle.loadString(path);
      yield LicenseEntryWithLineBreaks([family], text);
    }
  });
}
