import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/record_button.dart';
import 'package:echonotes/core/widgets/state_message.dart';

/// What the home screen shows before the first recording.
class NotesEmptyState extends StatelessWidget {
  const NotesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      // Keeps the message clear of the record button floating below it.
      padding: EdgeInsets.only(bottom: RecordButton.footprint),
      child: StateMessage(
        icon: Icons.mic_none_rounded,
        title: 'No notes yet',
        message:
            'Tap the record button below to capture your first conversation.',
      ),
    );
  }
}
