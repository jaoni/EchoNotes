import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/widgets/status_badge.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';

/// Where a note is in processing, in a few words. Shows nothing once the
/// note is ready.
class NoteStatusBadge extends StatelessWidget {
  const NoteStatusBadge({super.key, required this.status});

  final NoteStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      NoteStatus.recording => const StatusBadge(
        icon: Icons.mic_none_rounded,
        label: 'Recording…',
      ),
      NoteStatus.uploading => const StatusBadge(
        icon: Icons.cloud_upload_outlined,
        label: 'Uploading…',
      ),
      NoteStatus.queued => const StatusBadge(
        icon: Icons.hourglass_empty_rounded,
        label: 'Waiting in line…',
      ),
      NoteStatus.transcribing => const StatusBadge(
        icon: Icons.graphic_eq_rounded,
        label: 'Transcribing…',
      ),
      NoteStatus.writingNotes => const StatusBadge(
        icon: Icons.edit_note_rounded,
        label: 'Writing notes…',
      ),
      NoteStatus.failed => const StatusBadge(
        icon: Icons.error_outline_rounded,
        label: "Couldn't finish · Tap to retry",
        tone: StatusBadgeTone.error,
      ),
      NoteStatus.ready => const SizedBox.shrink(),
    };
  }
}
