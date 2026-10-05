import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/app/app.dart';
import 'package:echonotes/core/database/app_database_provider.dart';
import 'package:echonotes/core/theme/app_colors.dart';
import 'package:echonotes/features/design_preview/presentation/design_preview_screen.dart';
import 'package:echonotes/features/notes/data/audio_file_store_provider.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/recording/data/recording_service_providers.dart';

import '../helpers/fake_audio_file_store.dart';
import '../helpers/fake_recording_services.dart';
import '../helpers/test_database.dart';

void main() {
  /// The app wired as it ships, on a new database in memory.
  Widget app() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWith((ref) {
          final database = inMemoryDatabase();
          ref.onDispose(database.close);
          return database;
        }),
        audioFileStoreProvider.overrideWithValue(FakeAudioFileStore()),
        recordingPreferencesProvider.overrideWithValue(
          FakeRecordingPreferences(),
        ),
      ],
      child: const EchoNotesApp(),
    );
  }

  testWidgets('a debug build starts with the sample notes in its database', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('EchoNotes'), findsOneWidget);
    expect(find.text('Weekly product sync'), findsOneWidget);
  });

  testWidgets("follows the phone's dark mode setting", (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.text('EchoNotes')));
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.dark.background);
  });

  testWidgets('opens the design preview from home in debug builds', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Design preview'));
    await tester.pumpAndSettle();

    expect(find.byType(DesignPreviewScreen), findsOneWidget);
  });

  testWidgets("opens screens as Material pages, with the platform's motion", (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Weekly product sync'));
    await tester.pumpAndSettle();

    // A Material page takes its transition from the theme: iOS's slide, with
    // swipe to go back, and Android's fade. go_router only builds one when
    // the app uses the same Material library it does. Otherwise screens
    // quietly open with no transition at all.
    final route = ModalRoute.of(tester.element(find.byType(NoteDetailScreen)));
    expect(route, isA<MaterialRouteTransitionMixin<void>>());
  });
}
