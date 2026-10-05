import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/formatting/duration_format.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';

/// Where in the recording playback is: a slider, with the time played and
/// the whole length at either end. The slider is disabled without [onSeek].
class AudioPlayerPosition extends StatelessWidget {
  const AudioPlayerPosition({
    super.key,
    required this.duration,
    required this.position,
    required this.onSeek,
  });

  final Duration duration;
  final Duration position;
  final ValueChanged<Duration>? onSeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final timeStyle = context.textTheme.labelMedium?.copyWith(
      color: colors.textSecondary,
      fontFeatures: AppTextStyles.tabularFigures,
    );
    // A slider needs a range, even for an empty recording. The player may
    // also report a moment past the saved length.
    final totalMs = math.max(1, duration.inMilliseconds);
    final positionMs = position.inMilliseconds.clamp(0, totalMs);
    final onSeek = this.onSeek;

    return Column(
      mainAxisSize: MainAxisSize.min,
      // Full width, so the times can sit at either end.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'Position in recording',
          child: Slider(
            value: positionMs.toDouble(),
            max: totalMs.toDouble(),
            semanticFormatterCallback: (value) =>
                formatClock(Duration(milliseconds: value.round())),
            onChanged: onSeek == null
                ? null
                : (value) => onSeek(Duration(milliseconds: value.round())),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          // Side by side, or stacked when large text won't fit.
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              Text(
                formatClock(Duration(milliseconds: positionMs)),
                style: timeStyle,
              ),
              Text(formatClock(duration), style: timeStyle),
            ],
          ),
        ),
      ],
    );
  }
}
