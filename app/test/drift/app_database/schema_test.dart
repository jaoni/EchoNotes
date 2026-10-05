import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/database/app_database.dart';

import 'generated/schema.dart';

/// Guards the saved schema snapshots in drift_schemas/, which the migration
/// tests are built from. See "Changing the database schema" in CLAUDE.md.
void main() {
  test('a new database matches the saved schema of its version', () async {
    // Fails when a table changed without a new schema version, or when the
    // version went up without running make-migrations.
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await SchemaVerifier(GeneratedHelper())
        .migrateAndValidate(db, db.schemaVersion);
  });

  test('an older build refuses a database from a newer one', () async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(
          setup: (raw) => raw.execute('PRAGMA user_version = 99'),
        ),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);

    await expectLater(db.select(db.notes).get(), throwsStateError);
  });
}
