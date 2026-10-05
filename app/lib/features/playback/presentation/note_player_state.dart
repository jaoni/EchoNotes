enum NotePlayerStatus {
  loading,
  ready,

  /// The recording couldn't be opened.
  failed,
}

/// What a note's player shows.
class NotePlayerState {
  const NotePlayerState({
    this.status = NotePlayerStatus.loading,
    this.isPlaying = false,
    this.position = Duration.zero,
  });

  final NotePlayerStatus status;
  final bool isPlaying;
  final Duration position;

  NotePlayerState copyWith({
    NotePlayerStatus? status,
    bool? isPlaying,
    Duration? position,
  }) {
    return NotePlayerState(
      status: status ?? this.status,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
    );
  }
}
