import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:echonotes/core/widgets/note_card.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/presentation/confirm_and_delete_note.dart';
import 'package:echonotes/features/notes/presentation/note_detail_screen.dart';
import 'package:echonotes/features/notes/presentation/note_formatting.dart';
import 'package:echonotes/features/notes/presentation/processing_screen.dart';
import 'package:echonotes/features/notes/presentation/widgets/note_status_badge.dart';

/// A note in the home list. Finished notes open their notes; the rest open
/// their progress, where a failed one can be retried. A long press offers
/// to delete it.
class NoteListItem extends ConsumerWidget {
  const NoteListItem({super.key, required this.note});

  final Note note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReady = note.status == NoteStatus.ready;

    return NoteCard(
      title: noteDisplayTitle(note),
      metadata: noteMetadata(context, note),
      badge: isReady ? null : NoteStatusBadge(status: note.status),
      // The card clamps it to a short preview.
      summary: note.summary.split('\n').first,
      tags: note.tags,
      onTap: () => context.push(
        isReady
            ? NoteDetailScreen.location(note.id)
            : ProcessingScreen.location(note.id),
      ),
      onLongPress: () => confirmAndDeleteNote(context, ref, noteId: note.id),
      longPressLabel: 'Delete note',
    );
  }
}
