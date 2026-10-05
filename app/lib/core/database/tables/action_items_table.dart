import 'package:drift/drift.dart';

import 'package:echonotes/core/database/tables/notes_table.dart';

/// The action items of a note, in [position] order.
@DataClassName('ActionItemRow')
@TableIndex(name: 'action_items_note_id', columns: {#noteId, #position})
class ActionItems extends Table {
  TextColumn get id => text()();
  TextColumn get noteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();

  /// Called `text` in SQL, like `KeyPoints.content`.
  TextColumn get content => text().named('text')();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
