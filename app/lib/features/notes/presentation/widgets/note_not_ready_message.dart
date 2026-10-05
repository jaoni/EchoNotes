import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/core/widgets/state_message.dart';
import 'package:echonotes/features/notes/presentation/processing_screen.dart';

/// Shown when a note is opened before its notes are written, for example
/// from an old link. Points to its progress instead.
class NoteNotReadyMessage extends StatelessWidget {
  const NoteNotReadyMessage({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.hourglass_empty_rounded,
      title: "These notes aren't ready yet",
      action: FilledButton(
        onPressed: () => context.go(ProcessingScreen.location(noteId)),
        child: const Text('See progress'),
      ),
    );
  }
}
