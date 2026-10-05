import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/confirm_dialog.dart';

/// Asks before throwing a recording away. Closes with true to discard.
class DiscardRecordingDialog extends StatelessWidget {
  const DiscardRecordingDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const ConfirmDialog(
      title: 'Discard this recording?',
      message: "What you've recorded so far will be deleted.",
      cancelLabel: 'Keep recording',
      confirmLabel: 'Discard',
    );
  }
}
