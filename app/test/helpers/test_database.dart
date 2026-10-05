import 'package:drift/drift.dart';
import 'package:drift/native.dart';

import 'package:echonotes/core/database/app_database.dart';

/// A new, empty database that lives in memory.
///
/// Its streams close the moment it does, so a widget test doesn't end with
/// a timer still pending.
AppDatabase inMemoryDatabase() {
  return AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
}
