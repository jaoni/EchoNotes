import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/core/widgets/state_message.dart';
import 'package:echonotes/features/notes/presentation/home_screen.dart';

/// Shown when a link points to a note that doesn't exist (any more).
class MissingNoteMessage extends StatelessWidget {
  const MissingNoteMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.search_off_rounded,
      title: "This note isn't here",
      message: 'It may have been deleted.',
      action: FilledButton(
        onPressed: () => context.go(HomeScreen.routePath),
        child: const Text('Back to notes'),
      ),
    );
  }
}
