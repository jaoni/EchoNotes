import 'package:material_ui/material_ui.dart';

/// After the phone stopped EchoNotes while it recorded in the background:
/// says what was kept, and how to stop it happening again. Closes with true
/// to open the settings.
class RecordingCutOffDialog extends StatelessWidget {
  const RecordingCutOffDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.battery_alert_outlined),
      title: const Text('Your recording was cut off'),
      // Scrolls, so very large text still fits.
      scrollable: true,
      content: const Text(
        'Your phone stopped EchoNotes while it was recording in the '
        'background. What was recorded is saved.\n\n'
        "To keep this from happening, open EchoNotes' settings and set its "
        'battery use to Unrestricted. Some phones also have their own '
        'setting for apps that run in the background.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Open settings'),
        ),
      ],
    );
  }
}
