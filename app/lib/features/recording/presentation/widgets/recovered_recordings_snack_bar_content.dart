import 'package:material_ui/material_ui.dart';

/// Says that recordings cut off when the app closed were saved after all.
class RecoveredRecordingsSnackBarContent extends StatelessWidget {
  const RecoveredRecordingsSnackBarContent({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      count == 1
          ? 'A recording was cut off when EchoNotes closed. What was '
                'recorded is saved.'
          : '$count recordings were cut off when EchoNotes closed. What was '
                'recorded is saved.',
    );
  }
}
