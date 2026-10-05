import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_motion.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';

enum ProcessingStepState { waiting, active, done }

/// One step on the way to a finished note: an indicator, a name and a short
/// explanation. The indicator carries a spoken label for screen readers.
class ProcessingStepTile extends StatelessWidget {
  const ProcessingStepTile({
    super.key,
    required this.label,
    required this.caption,
    required this.state,
  });

  static const _indicatorSize = 24.0;
  static const _spinnerInset = 3.0;
  static const _spinnerStroke = 2.5;

  final String label;
  final String caption;
  final ProcessingStepState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = context.textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final indicator = switch (state) {
      ProcessingStepState.done => Icon(
        Icons.check_circle_rounded,
        size: _indicatorSize,
        color: colors.success,
        semanticLabel: 'Done',
      ),
      // With less motion, a still dot instead of a spinning ring.
      ProcessingStepState.active when reduceMotion => Icon(
        Icons.radio_button_checked_rounded,
        size: _indicatorSize,
        color: colors.accent,
        semanticLabel: 'In progress',
      ),
      ProcessingStepState.active => SizedBox.square(
        dimension: _indicatorSize,
        child: Padding(
          padding: const EdgeInsets.all(_spinnerInset),
          child: CircularProgressIndicator(
            strokeWidth: _spinnerStroke,
            color: colors.accent,
            semanticsLabel: 'In progress',
          ),
        ),
      ),
      ProcessingStepState.waiting => Icon(
        Icons.radio_button_unchecked_rounded,
        size: _indicatorSize,
        color: colors.textSecondary,
        semanticLabel: 'Not started',
      ),
    };

    return MergeSemantics(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : AppMotion.medium,
            child: KeyedSubtree(key: ValueKey(state), child: indicator),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: state == ProcessingStepState.waiting
                        ? colors.textSecondary
                        : colors.textPrimary,
                  ),
                ),
                Text(
                  caption,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
