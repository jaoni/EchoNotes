import 'package:material_ui/material_ui.dart';

/// The search field above the notes. Only the look for now: searching
/// arrives with the database.
class NotesSearchField extends StatelessWidget {
  const NotesSearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Search notes',
        prefixIcon: Icon(Icons.search_rounded),
      ),
      textInputAction: TextInputAction.search,
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
    );
  }
}
