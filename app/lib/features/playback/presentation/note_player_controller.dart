import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/notes/data/audio_file_store_provider.dart';
import 'package:echonotes/features/playback/data/audio_playback_provider.dart';
import 'package:echonotes/features/playback/domain/audio_playback.dart';
import 'package:echonotes/features/playback/presentation/note_player_state.dart';

/// Plays the recording with the given file name, for as long as its note
/// is open.
final notePlayerProvider = NotifierProvider.autoDispose
    .family<NotePlayerController, NotePlayerState, String>(
      NotePlayerController.new,
    );

/// Basic playback of a note's recording: play, pause and move to a point.
/// The full player comes in Step 9.
class NotePlayerController extends Notifier<NotePlayerState> {
  NotePlayerController(this.audioFileName);

  final String audioFileName;
  late AudioPlayback _playback;

  @override
  NotePlayerState build() {
    final playback = ref.watch(audioPlaybackFactoryProvider)();
    _playback = playback;
    final subscriptions = [
      playback.positions.listen((position) {
        state = state.copyWith(position: position);
      }),
      playback.playingChanges.listen((isPlaying) {
        state = state.copyWith(isPlaying: isPlaying);
      }),
    ];
    ref.onDispose(() {
      for (final subscription in subscriptions) {
        unawaited(subscription.cancel());
      }
      unawaited(playback.dispose());
    });

    unawaited(_load());
    return const NotePlayerState();
  }

  Future<void> togglePlaying() async {
    if (state.status != NotePlayerStatus.ready) return;
    try {
      if (state.isPlaying) {
        await _playback.pause();
      } else {
        await _playback.play();
      }
    } catch (error) {
      _log("Couldn't play or pause", error);
    }
  }

  Future<void> seek(Duration position) async {
    if (state.status != NotePlayerStatus.ready) return;
    state = state.copyWith(position: position);
    try {
      await _playback.seek(position);
    } catch (error) {
      _log("Couldn't move in the recording", error);
    }
  }

  Future<void> _load() async {
    try {
      final path = await ref.read(audioFileStoreProvider).pathOf(audioFileName);
      await _playback.load(path);
      if (ref.mounted) {
        state = state.copyWith(status: NotePlayerStatus.ready);
      }
    } catch (error) {
      _log("Couldn't open the recording $audioFileName", error);
      if (ref.mounted) {
        state = state.copyWith(status: NotePlayerStatus.failed);
      }
    }
  }

  void _log(String message, Object error) {
    developer.log(message, name: 'echonotes.playback', error: error);
  }
}
