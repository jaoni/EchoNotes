import 'package:echonotes/features/notes/domain/action_item.dart';
import 'package:echonotes/features/notes/domain/key_point.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/domain/transcript_segment.dart';

/// One recorded conversation and the notes made from it.
///
/// While [status] is still processing, only the recording's facts are known:
/// the title, summary and the lists stay empty until the notes are written.
class Note {
  const Note({
    required this.id,
    required this.recordedAt,
    required this.duration,
    required this.status,
    this.audioFileName,
    this.title = '',
    this.summary = '',
    this.keyPoints = const [],
    this.actionItems = const [],
    this.tags = const [],
    this.transcript = const [],
  });

  final String id;

  /// When the recording started.
  final DateTime recordedAt;

  /// How long the recording is.
  final Duration duration;
  final NoteStatus status;

  /// The recording's file name, without its folder: `AudioFileStore` finds
  /// it. Null when there's no recording on this phone, like the sample
  /// notes.
  final String? audioFileName;

  /// Empty until the notes are written.
  final String title;
  final String summary;
  final List<KeyPoint> keyPoints;
  final List<ActionItem> actionItems;
  final List<String> tags;
  final List<TranscriptSegment> transcript;

  Note copyWith({
    NoteStatus? status,
    String? title,
    String? summary,
    List<KeyPoint>? keyPoints,
    List<ActionItem>? actionItems,
    List<String>? tags,
    List<TranscriptSegment>? transcript,
  }) {
    return Note(
      id: id,
      recordedAt: recordedAt,
      duration: duration,
      status: status ?? this.status,
      audioFileName: audioFileName,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      actionItems: actionItems ?? this.actionItems,
      tags: tags ?? this.tags,
      transcript: transcript ?? this.transcript,
    );
  }
}
