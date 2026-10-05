import 'package:drift/drift.dart';

/// One recorded conversation. Its key points, action items, transcript and
/// tags live in their own tables and are deleted with it.
///
/// Every change to a note or to one of its parts also sets [updatedAt].
/// Sync will rely on that, and so do the live note streams.
@DataClassName('NoteRow')
@TableIndex(name: 'notes_created_at', columns: {#createdAt})
class Notes extends Table {
  /// A UUID, so notes made on different phones never clash on the server.
  TextColumn get id => text()();

  /// Empty until the notes are written.
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get summary => text().withDefault(const Constant(''))();

  /// Only the file's name. The folder can move (on iOS its path changes
  /// with app updates), so the full path is built when it's needed.
  ///
  /// Null when there's no recording on this phone, like the debug sample
  /// notes.
  TextColumn get audioFileName => text().nullable()();

  IntColumn get durationMs => integer()();

  /// Spelled like the server: `uploading`, `queued`, `transcribing`,
  /// `writing_notes`, `ready` or `failed`. Before those, `recording` while
  /// the recording runs (the server never sees that one).
  TextColumn get status => text()();

  /// Why processing failed. Filled in by the backend step.
  TextColumn get errorMessage => text().nullable()();

  /// The spoken language, found during transcription. Filled in by the
  /// backend step.
  TextColumn get language => text().nullable()();

  /// When the recording started. The notes list is sorted by it.
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => ['CHECK (duration_ms >= 0)'];
}
