/// Where a note is on its way from a recording to finished notes.
///
/// A note is made the moment recording starts, so nothing is lost if the
/// app closes mid-recording. Then it matches the planned background job:
/// the app uploads the audio, the backend queues a job, and a worker
/// transcribes it and then writes the notes. The server spells
/// [writingNotes] as `writing_notes`.
enum NoteStatus {
  /// Still being recorded. A note left like this when the app closed is
  /// recovered on the next launch.
  recording,
  uploading,
  queued,
  transcribing,
  writingNotes,
  ready,
  failed;

  /// Recorded and on its way to becoming a note.
  bool get isProcessing => switch (this) {
    uploading || queued || transcribing || writingNotes => true,
    recording || ready || failed => false,
  };
}
