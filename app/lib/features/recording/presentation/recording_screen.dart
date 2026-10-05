import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/features/notes/presentation/home_screen.dart';
import 'package:echonotes/features/notes/presentation/processing_screen.dart';
import 'package:echonotes/features/recording/data/recording_service_providers.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';
import 'package:echonotes/features/recording/presentation/widgets/discard_recording_dialog.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_ending_snack_bar_content.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_layout.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_problem_message.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_reminder_message.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_status_label.dart';

/// Records a conversation. Recording starts as soon as the screen opens,
/// once the microphone is allowed.
///
/// Stopping saves the recording and moves on to its processing. Leaving any
/// other way (close button, back gesture) asks first, so a recording is
/// never lost by accident.
class RecordingScreen extends ConsumerWidget {
  const RecordingScreen({super.key});

  /// Its path under the home route, and the location to go to.
  static const routePath = 'record';
  static const location = '/record';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      recordingControllerProvider.select((state) => state.phase),
      (previous, phase) => _onPhaseChanged(context, ref, phase),
    );
    final controller = ref.read(recordingControllerProvider.notifier);
    final phase = ref.watch(
      recordingControllerProvider.select((state) => state.phase),
    );
    final canDiscard =
        phase == RecordingPhase.recording || phase == RecordingPhase.paused;
    final isLeaving =
        phase == RecordingPhase.stopped || phase == RecordingPhase.discarded;
    // Nothing recorded yet, so nothing to lose.
    final canClose = !phase.hasAudio && !isLeaving;

    return PopScope(
      canPop: canClose,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && canDiscard) _confirmDiscard(context, ref);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: canDiscard ? 'Discard recording' : 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: canDiscard
                ? () => _confirmDiscard(context, ref)
                : (canClose ? () => context.go(HomeScreen.routePath) : null),
          ),
          title: const RecordingStatusLabel(),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: switch (phase) {
            RecordingPhase.reminder => RecordingReminderMessage(
              onContinue: controller.continueAfterReminder,
            ),
            RecordingPhase.permissionDenied ||
            RecordingPhase.permissionBlocked ||
            RecordingPhase.notEnoughSpace ||
            RecordingPhase.couldNotStart => RecordingProblemMessage(
              phase: phase,
              onRetry: controller.retry,
              onOpenSettings: controller.openSettings,
            ),
            _ => RecordingLayout(onStop: controller.stop),
          },
        ),
      ),
    );
  }

  void _onPhaseChanged(
    BuildContext context,
    WidgetRef ref,
    RecordingPhase phase,
  ) {
    switch (phase) {
      case RecordingPhase.stopped:
        final state = ref.read(recordingControllerProvider);
        final ending = state.ending;
        if (RecordingEndingSnackBarContent.isNeededFor(ending)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: RecordingEndingSnackBarContent(
                ending: ending!,
                maxLength: ref.read(recordingLimitsProvider).maxLength,
              ),
            ),
          );
        }
        // Replaces this screen, so back from processing goes to the list.
        context.go(ProcessingScreen.location(state.noteId!));
      case RecordingPhase.discarded:
        context.go(HomeScreen.routePath);
      default:
        break;
    }
  }

  Future<void> _confirmDiscard(BuildContext context, WidgetRef ref) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => const DiscardRecordingDialog(),
    );
    if (discard == true && context.mounted) {
      await ref.read(recordingControllerProvider.notifier).discard();
    }
  }
}
