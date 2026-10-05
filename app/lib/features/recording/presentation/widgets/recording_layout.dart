import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';
import 'package:echonotes/features/recording/presentation/widgets/live_transcript.dart';
import 'package:echonotes/features/recording/presentation/widgets/live_transcript_header.dart';
import 'package:echonotes/features/recording/presentation/widgets/live_waveform.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_controls.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_notice_banner.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_timer.dart';

/// Any notice, timer, waveform, live transcript and controls, top to
/// bottom.
///
/// The transcript takes the space that's left. On short screens (small
/// phones, landscape, very large text) everything scrolls instead, with the
/// transcript at a fixed height, so nothing gets cut off.
class RecordingLayout extends ConsumerWidget {
  const RecordingLayout({super.key, required this.onStop});

  static const _compactBelowHeight = 520.0;
  static const _compactTranscriptHeight = 200.0;

  /// Extra height a notice needs before the roomy layout is used: a long
  /// one, in very large text.
  static const _noticeHeight = 200.0;

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNotice = ref.watch(
      recordingControllerProvider.select((state) => state.notice != null),
    );
    final notice = [
      if (hasNotice) ...[
        const RecordingNoticeBanner(),
        const SizedBox(height: AppSpacing.lg),
      ],
    ];
    final controls = RecordingControls(onStop: onStop);
    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.page,
      vertical: AppSpacing.lg,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactBelow = hasNotice
            ? _compactBelowHeight + _noticeHeight
            : _compactBelowHeight;
        if (constraints.maxHeight < compactBelow) {
          return ListView(
            padding: padding,
            children: [
              ...notice,
              const RecordingTimer(),
              const SizedBox(height: AppSpacing.lg),
              const LiveWaveform(),
              const SizedBox(height: AppSpacing.xl),
              const LiveTranscriptHeader(),
              const SizedBox(height: AppSpacing.sm),
              const SizedBox(
                height: _compactTranscriptHeight,
                child: LiveTranscript(),
              ),
              const SizedBox(height: AppSpacing.lg),
              controls,
            ],
          );
        }

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...notice,
              const RecordingTimer(),
              const SizedBox(height: AppSpacing.lg),
              const LiveWaveform(),
              const SizedBox(height: AppSpacing.xl),
              const LiveTranscriptHeader(),
              const SizedBox(height: AppSpacing.sm),
              const Expanded(child: LiveTranscript()),
              const SizedBox(height: AppSpacing.lg),
              controls,
            ],
          ),
        );
      },
    );
  }
}
