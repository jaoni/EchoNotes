import 'package:echonotes/core/database/app_database.dart';
import 'package:echonotes/features/notes/domain/action_item.dart';
import 'package:echonotes/features/notes/domain/key_point.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/domain/transcript_segment.dart';

/// How a status is stored: spelled like the server. Written out rather than
/// taken from the enum's names, so renaming a value in Dart can never break
/// saved notes.
String noteStatusCode(NoteStatus status) {
  return switch (status) {
    NoteStatus.recording => 'recording',
    NoteStatus.uploading => 'uploading',
    NoteStatus.queued => 'queued',
    NoteStatus.transcribing => 'transcribing',
    NoteStatus.writingNotes => 'writing_notes',
    NoteStatus.ready => 'ready',
    NoteStatus.failed => 'failed',
  };
}

/// The status stored as [code]. Throws on a code this build doesn't know,
/// rather than guess and, say, process a finished note again.
NoteStatus noteStatusFromCode(String code) {
  return switch (code) {
    'recording' => NoteStatus.recording,
    'uploading' => NoteStatus.uploading,
    'queued' => NoteStatus.queued,
    'transcribing' => NoteStatus.transcribing,
    'writing_notes' => NoteStatus.writingNotes,
    'ready' => NoteStatus.ready,
    'failed' => NoteStatus.failed,
    _ => throw FormatException('Unknown note status', code),
  };
}

/// [date] the way it's stored: in UTC, to the millisecond. Every stored date
/// then has the same shape, such as "2026-09-30T08:15:00.000Z", so sorting
/// them as text sorts them by time.
DateTime storedDate(DateTime date) {
  return DateTime.fromMillisecondsSinceEpoch(
    date.millisecondsSinceEpoch,
    isUtc: true,
  );
}

/// A note made from its row and the rows of its parts, each already in
/// order.
Note noteFromRows(
  NoteRow note, {
  List<NoteTagRow> tags = const [],
  List<KeyPointRow> keyPoints = const [],
  List<ActionItemRow> actionItems = const [],
  List<TranscriptSegmentRow> transcript = const [],
}) {
  return Note(
    id: note.id,
    recordedAt: note.createdAt.toLocal(),
    duration: Duration(milliseconds: note.durationMs),
    status: noteStatusFromCode(note.status),
    audioFileName: note.audioFileName,
    title: note.title,
    summary: note.summary,
    tags: [for (final tag in tags) tag.name],
    keyPoints: [for (final point in keyPoints) KeyPoint(text: point.content)],
    actionItems: [
      for (final item in actionItems)
        ActionItem(id: item.id, text: item.content, isDone: item.isDone),
    ],
    transcript: [
      for (final segment in transcript)
        TranscriptSegment(
          start: Duration(milliseconds: segment.startMs),
          end: Duration(milliseconds: segment.endMs),
          text: segment.content,
        ),
    ],
  );
}
