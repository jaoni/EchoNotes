import 'package:drift/drift.dart';

import 'package:echonotes/core/database/tables/notes_table.dart';

/// The transcript of a note, one stretch of speech per row, in the order of
/// [startMs].
@DataClassName('TranscriptSegmentRow')
@TableIndex(name: 'transcript_segments_note_id', columns: {#noteId, #startMs})
class TranscriptSegments extends Table {
  TextColumn get id => text()();
  TextColumn get noteId =>
      text().references(Notes, #id, onDelete: KeyAction.cascade)();

  /// Where the segment sits in the recording.
  IntColumn get startMs => integer()();
  IntColumn get endMs => integer()();

  /// Called `text` in SQL, like `KeyPoints.content`.
  TextColumn get content => text().named('text')();

  /// Who is speaking, when transcription can tell. Not filled in yet.
  TextColumn get speaker => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (start_ms >= 0 AND end_ms >= start_ms)',
  ];
}
