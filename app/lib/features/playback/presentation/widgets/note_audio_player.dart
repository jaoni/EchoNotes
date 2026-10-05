import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/playback/presentation/note_player_controller.dart';
import 'package:echonotes/features/playback/presentation/note_player_state.dart';
import 'package:echonotes/features/playback/presentation/widgets/audio_player_bar.dart';

/// The player for a note's recording. Stays disabled for a note without a
/// recording on this phone, like the sample notes.
class NoteAudioPlayer extends ConsumerWidget {
  const NoteAudioPlayer({
    super.key,
    required this.audioFileName,
    required this.duration,
  });

  final String? audioFileName;
  final Duration duration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioFileName = this.audioFileName;
    if (audioFileName == null) return AudioPlayerBar(duration: duration);

    final player = ref.watch(notePlayerProvider(audioFileName));
    final controller = ref.read(notePlayerProvider(audioFileName).notifier);
    final isReady = player.status == NotePlayerStatus.ready;

    return AudioPlayerBar(
      duration: duration,
      position: player.position,
      isPlaying: player.isPlaying,
      onPlayPause: isReady ? controller.togglePlaying : null,
      onSeek: isReady ? controller.seek : null,
      problem: player.status == NotePlayerStatus.failed
          ? "Couldn't play this recording."
          : null,
    );
  }
}
