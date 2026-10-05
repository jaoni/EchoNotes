import 'package:drift/drift.dart';

import 'package:echonotes/core/database/tables/notes_table.dart';

/// The tags of a note, in [position] order.
///
/// A table rather than a list inside the note, so "notes tagged X" is an
/// indexed lookup and "every tag, with counts" is one `GROUP BY`.
///
/// A row needs no id of its own: a note has each tag once, and the note's
/// UUID already makes the pair unique everywhere.
@DataClassName('NoteTagRow')
@TableIndex(name: 'note_tags_name', columns: {#name})
class NoteTags extends Table {
  TextColumn get noteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();

  /// Compared ignoring case, so "Meeting" and "meeting" are one tag, for
  /// both the key and filtering.
  TextColumn get name => text().customConstraint('NOT NULL COLLATE NOCASE')();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {noteId, name};
}
