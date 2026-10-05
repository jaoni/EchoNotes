import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/core/theme/app_motion.dart';
import 'package:echonotes/core/widgets/record_button.dart';
import 'package:echonotes/features/design_preview/presentation/design_preview_screen.dart';
import 'package:echonotes/features/notes/presentation/notes_providers.dart';
import 'package:echonotes/features/notes/presentation/widgets/load_error_message.dart';
import 'package:echonotes/features/notes/presentation/widgets/notes_empty_state.dart';
import 'package:echonotes/features/notes/presentation/widgets/notes_list.dart';
import 'package:echonotes/features/recording/data/recording_recovery_provider.dart';
import 'package:echonotes/features/recording/data/recording_service_providers.dart';
import 'package:echonotes/features/recording/presentation/recording_screen.dart';
import 'package:echonotes/features/recording/presentation/widgets/recording_cut_off_dialog.dart';
import 'package:echonotes/features/recording/presentation/widgets/recovered_recordings_snack_bar_content.dart';

/// The list of notes, with the record button always at hand.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(recordingRecoveryProvider, (previous, next) {
      final recovered = next.value;
      if (recovered == null || recovered.kept == 0) return;
      final background = ref.read(backgroundRecordingProvider);
      if (recovered.cutOffInBackground && background.hasBatterySettings) {
        _explainCutOff(context, ref);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: RecoveredRecordingsSnackBarContent(count: recovered.kept),
          ),
        );
      }
    });
    final notes = ref.watch(notesProvider);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EchoNotes'),
        actions: [
          if (kDebugMode)
            IconButton(
              tooltip: 'Design preview',
              icon: const Icon(Icons.palette_outlined),
              onPressed: () => context.push(DesignPreviewScreen.location),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : AppMotion.medium,
        child: notes.when(
          data: (notes) => notes.isEmpty
              ? const NotesEmptyState(key: ValueKey('empty'))
              : NotesList(key: const ValueKey('list'), notes: notes),
          error: (error, stackTrace) => LoadErrorMessage(
            key: const ValueKey('error'),
            title: "Couldn't load your notes",
            onRetry: () => ref.invalidate(notesProvider),
          ),
          loading: () => const Center(
            key: ValueKey('loading'),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: RecordButton(
        isRecording: false,
        onPressed: () => context.push(RecordingScreen.location),
      ),
    );
  }

  /// The phone stopped a recording in the background: says what was kept,
  /// and offers the battery settings that stop it happening again.
  Future<void> _explainCutOff(BuildContext context, WidgetRef ref) async {
    final background = ref.read(backgroundRecordingProvider);
    final openSettings = await showDialog<bool>(
      context: context,
      builder: (context) => const RecordingCutOffDialog(),
    );
    if (openSettings == true) await background.openBatterySettings();
  }
}
