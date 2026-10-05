import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/formatting/duration_format.dart';
import 'package:echonotes/core/widgets/feedback_banner.dart';
import 'package:echonotes/features/recording/data/recording_service_providers.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';

/// The most important thing to know while recording, if anything: why it
/// paused, a problem, or a limit coming up. Read out by screen readers when
/// it changes. A warning that the phone may stop the recording in the
/// background offers its battery settings.
class RecordingNoticeBanner extends ConsumerWidget {
  const RecordingNoticeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notice = ref.watch(
      recordingControllerProvider.select((state) => state.notice),
    );
    if (notice == null) return const SizedBox.shrink();

    final limit = formatLength(ref.watch(recordingLimitsProvider).maxLength);
    final (tone, icon, message) = switch (notice) {
      RecordingNotice.saveFailed => (
        FeedbackTone.error,
        Icons.error_outline_rounded,
        "Couldn't save the recording. It's safe on this phone: tap stop to "
            'try again.',
      ),
      RecordingNotice.resumeFailed => (
        FeedbackTone.error,
        Icons.mic_off_outlined,
        "Couldn't start the microphone again. If you're on a call, wait "
            'until it ends, then tap resume.',
      ),
      RecordingNotice.interrupted => (
        FeedbackTone.info,
        Icons.pause_circle_outline_rounded,
        'Paused while a call or another app uses the microphone. It carries '
            'on when that ends, or tap resume.',
      ),
      RecordingNotice.noSound => (
        FeedbackTone.info,
        Icons.mic_off_outlined,
        "We can't hear anything. Another app may be using the microphone.",
      ),
      RecordingNotice.limitedInBackground => (
        FeedbackTone.info,
        Icons.battery_alert_outlined,
        'Your phone may stop this recording if you leave EchoNotes or lock '
            'the screen. Allow EchoNotes to run in the background to keep it '
            'going.',
      ),
      RecordingNotice.limitSoon => (
        FeedbackTone.info,
        Icons.timer_outlined,
        'Recordings can be up to $limit long, so this one stops by itself '
            'in ${_minutesLeft(ref)} min.',
      ),
      RecordingNotice.lowSpace => (
        FeedbackTone.info,
        Icons.sd_storage_outlined,
        'Your phone is low on space: room for about '
            '${formatLength(_spaceLeft(ref))} of recording.',
      ),
    };

    final offersSettings = notice == RecordingNotice.limitedInBackground;

    return Semantics(
      liveRegion: true,
      child: FeedbackBanner(
        tone: tone,
        icon: icon,
        message: message,
        actionLabel: offersSettings ? 'Battery settings' : null,
        onAction: offersSettings
            ? ref.read(recordingControllerProvider.notifier).openBatterySettings
            : null,
      ),
    );
  }

  /// Whole minutes left, rounded up, so the last minute reads "1 min".
  int _minutesLeft(WidgetRef ref) {
    final maxLength = ref.watch(recordingLimitsProvider).maxLength;
    return ref.watch(
      recordingControllerProvider.select((state) {
        final left = maxLength - state.elapsed;
        return (left.inSeconds / 60).ceil().clamp(0, maxLength.inMinutes);
      }),
    );
  }

  Duration _spaceLeft(WidgetRef ref) {
    return ref.watch(
      recordingControllerProvider.select(
        (state) => state.spaceLeft ?? Duration.zero,
      ),
    );
  }
}
