import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';

import 'package:echonotes/features/playback/domain/audio_playback.dart';

/// Plays recordings with `just_audio`: AVPlayer on iOS, ExoPlayer on
/// Android. Both read the ADTS files recordings are saved in.
class JustAudioPlayback implements AudioPlayback {
  final _player = AudioPlayer();

  @override
  Future<void> load(String path) async {
    // Spoken audio, and not muted by the iPhone's silent switch.
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    await _player.setFilePath(path);
  }

  @override
  Future<void> play() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    // Completes only when playback stops, so it isn't waited for.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Stream<Duration> get positions => _player.positionStream;

  @override
  Stream<bool> get playingChanges {
    return _player.playerStateStream
        .map(
          (state) =>
              state.playing &&
              state.processingState != ProcessingState.completed,
        )
        .distinct();
  }

  @override
  Future<void> dispose() => _player.dispose();
}
