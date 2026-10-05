import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:echonotes/core/database/app_database.dart';

/// The app's database, open for as long as the app runs.
///
/// drift_flutter runs every query on a background isolate, so the UI stays
/// smooth, and looks the folder up again on every launch. The file lives in
/// Application Support: private to the app and included in backups. Tests
/// override this with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase(
    driftDatabase(
      name: 'echonotes',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    ),
  );
  ref.onDispose(database.close);
  return database;
});
