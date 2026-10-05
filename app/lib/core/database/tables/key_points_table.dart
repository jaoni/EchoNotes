import 'package:drift/drift.dart';

import 'package:echonotes/core/database/tables/notes_table.dart';

/// The key points of a note, in [position] order.
@DataClassName('KeyPointRow')
@TableIndex(name: 'key_points_note_id', columns: {#noteId, #position})
class KeyPoints extends Table {
  TextColumn get id => text()();
  TextColumn get noteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();

  /// Called `text` in SQL. A table can't have a getter named `text`, since
  /// that's the name of the method that makes text columns.
  TextColumn get content => text().named('text')();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
