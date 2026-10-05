import 'dart:async';

import 'package:echonotes/features/playback/domain/audio_playback.dart';

/// Pretends to play, and remembers what it was asked.
class FakeAudioPlayback implements AudioPlayback {
  final _positions = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();

  String? loadedPath;
  var isPlaying = false;
  var isDisposed = false;
  Duration? seekedTo;

  /// When set, loading throws this instead.
  Object? loadError;

  @override
  Future<void> load(String path) async {
    if (loadError case final error?) throw error;
    loadedPath = path;
  }

  @override
  Future<void> play() async => _playing.add(isPlaying = true);

  @override
  Future<void> pause() async => _playing.add(isPlaying = false);

  @override
  Future<void> seek(Duration position) async {
    seekedTo = position;
    _positions.add(position);
  }

  /// Pretends playback moved on to [position].
  void moveTo(Duration position) => _positions.add(position);

  @override
  Stream<Duration> get positions => _positions.stream;

  @override
  Stream<bool> get playingChanges => _playing.stream;

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await _positions.close();
    await _playing.close();
  }
}
