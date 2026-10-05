import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/app/rise_in_page.dart';
import 'package:echonotes/features/design_preview/presentation/design_preview_screen.dart';
import 'package:echonotes/features/notes/presentation/home_screen.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/notes/presentation/processing_screen.dart';
import 'package:echonotes/features/recording/presentation/recording_screen.dart';

/// App-wide router. Lives in a provider so it can later react to auth state.
///
/// Every screen sits under home, so going straight to any of them (later,
/// from a "your note is ready" notification) still leaves home behind it.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: HomeScreen.routePath,
    routes: [
      GoRoute(
        path: HomeScreen.routePath,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: RecordingScreen.routePath,
            pageBuilder: (context, state) =>
                RiseInPage(key: state.pageKey, child: const RecordingScreen()),
          ),
          GoRoute(
            path: ProcessingScreen.routePath,
            builder: (context, state) =>
                ProcessingScreen(noteId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: NoteDetailScreen.routePath,
            builder: (context, state) =>
                NoteDetailScreen(noteId: state.pathParameters['id']!),
          ),
          // Debug builds only, so the design preview never ships.
          if (kDebugMode)
            GoRoute(
              path: DesignPreviewScreen.routePath,
              builder: (context, state) => const DesignPreviewScreen(),
            ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
