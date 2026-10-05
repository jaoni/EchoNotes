import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/playback/presentation/widgets/audio_player_position.dart';
import 'package:echonotes/features/playback/presentation/widgets/audio_player_problem.dart';

/// The player at the bottom of a note: play or pause, and where in the
/// recording you are. Shows [problem], with an icon, instead of the
/// position when the recording can't be played.
class AudioPlayerBar extends StatelessWidget {
  const AudioPlayerBar({
    super.key,
    required this.duration,
    this.position = Duration.zero,
    this.isPlaying = false,
    this.onPlayPause,
    this.onSeek,
    this.problem,
  });

  final Duration duration;
  final Duration position;
  final bool isPlaying;

  /// Null while nothing can be played.
  final VoidCallback? onPlayPause;
  final ValueChanged<Duration>? onSeek;
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final problem = this.problem;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconButton.filled(
                tooltip: isPlaying ? 'Pause' : 'Play',
                onPressed: onPlayPause,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
              Expanded(
                child: problem == null
                    ? AudioPlayerPosition(
                        duration: duration,
                        position: position,
                        onSeek: onSeek,
                      )
                    : AudioPlayerProblem(message: problem),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
