import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/app/router.dart';
import 'package:echonotes/core/theme/app_theme.dart';
import 'package:echonotes/features/notes/data/note_processing_provider.dart';
import 'package:echonotes/features/recording/data/recording_recovery_provider.dart';

class EchoNotesApp extends ConsumerWidget {
  const EchoNotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps notes moving through processing for as long as the app runs,
    // whichever screen is open.
    ref.watch(noteProcessingProvider);
    // Saves recordings cut off when the app last closed, once, at launch.
    ref.listen(recordingRecoveryProvider, (previous, next) {});
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'EchoNotes',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follow the phone's light/dark setting.
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
