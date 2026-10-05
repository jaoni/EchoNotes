import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/features/notes/domain/note_status.dart';
import 'package:echonotes/features/notes/presentation/widgets/processing_step_tile.dart';

/// The three steps a recording goes through, marked done, active or waiting
/// for the note's [status]. Waiting in the queue counts as transcribing.
class ProcessingSteps extends StatelessWidget {
  const ProcessingSteps({super.key, required this.status});

  final NoteStatus status;

  /// The step being worked on: 0 to 2, or 3 when all are done.
  int get _activeStep => switch (status) {
    // Still recording, or about to be recovered: uploading is next.
    NoteStatus.recording || NoteStatus.uploading => 0,
    NoteStatus.queued || NoteStatus.transcribing => 1,
    NoteStatus.writingNotes => 2,
    NoteStatus.ready => 3,
    // Failed notes show an error instead of these steps.
    NoteStatus.failed => 0,
  };

  ProcessingStepState _stateOf(int step) {
    if (step < _activeStep) return ProcessingStepState.done;
    if (step == _activeStep) return ProcessingStepState.active;
    return ProcessingStepState.waiting;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProcessingStepTile(
          label: 'Uploading',
          caption: 'Sending your recording',
          state: _stateOf(0),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProcessingStepTile(
          label: 'Transcribing',
          caption: status == NoteStatus.queued
              ? 'Waiting in line…'
              : 'Turning speech into text',
          state: _stateOf(1),
        ),
        const SizedBox(height: AppSpacing.lg),
        ProcessingStepTile(
          label: 'Writing your notes',
          caption: 'Summary, key points and action items',
          state: _stateOf(2),
        ),
      ],
    );
  }
}
