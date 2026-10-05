import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/state_message.dart';

/// Shown once, before the first recording: tell people they're being
/// recorded.
class RecordingReminderMessage extends StatelessWidget {
  const RecordingReminderMessage({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return StateMessage(
      icon: Icons.record_voice_over_outlined,
      title: 'Let people know',
      message:
          "Before you record, tell everyone that you're recording. In many "
          'places, recording people without telling them is against the law.',
      action: FilledButton.icon(
        onPressed: onContinue,
        icon: const Icon(Icons.mic_rounded),
        label: const Text('Start recording'),
      ),
    );
  }
}
