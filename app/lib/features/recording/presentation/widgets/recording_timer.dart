import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/formatting/duration_format.dart';
import 'package:echonotes/core/theme/app_text_styles.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';

/// The large recording timer. Rebuilds once a second, and shrinks rather
/// than overflow when the text is very large.
class RecordingTimer extends ConsumerWidget {
  const RecordingTimer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seconds = ref.watch(
      recordingControllerProvider.select((state) => state.elapsed.inSeconds),
    );

    return Semantics(
      label: 'Recording time',
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          formatClock(Duration(seconds: seconds)),
          style: AppTextStyles.timer.copyWith(
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
