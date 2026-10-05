import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/widgets/record_button.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/presentation/widgets/note_list_item.dart';
import 'package:echonotes/features/notes/presentation/widgets/notes_search_field.dart';

/// The search field and every note, newest first. Leaves room at the bottom
/// so the last card can scroll clear of the record button.
class NotesList extends StatelessWidget {
  const NotesList({super.key, required this.notes});

  final List<Note> notes;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.lg,
          ),
          sliver: SliverToBoxAdapter(child: NotesSearchField()),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.page,
            0,
            AppSpacing.page,
            RecordButton.footprint + AppSpacing.lg + bottomInset,
          ),
          sliver: SliverList.separated(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteListItem(key: ValueKey(note.id), note: note);
            },
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.md),
          ),
        ),
      ],
    );
  }
}
