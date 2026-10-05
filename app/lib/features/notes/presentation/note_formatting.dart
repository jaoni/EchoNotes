import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/formatting/duration_format.dart';
import 'package:echonotes/features/notes/domain/note.dart';

/// Shown until the notes, and with them the real title, are written.
const untitledNoteTitle = 'New recording';

/// The title to show, with a stand-in while the note is being processed.
String noteDisplayTitle(Note note) {
  return note.title.isEmpty ? untitledNoteTitle : note.title;
}

/// When and how long: "Today · 9:30 AM · 32 min".
///
/// The time follows the phone's 12 or 24 hour setting. [now] is only for
/// tests.
String noteMetadata(BuildContext context, Note note, {DateTime? now}) {
  final localizations = MaterialLocalizations.of(context);
  final day = _dayLabel(localizations, note.recordedAt, now ?? DateTime.now());
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(note.recordedAt),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$day · $time · ${formatLength(note.duration)}';
}

String _dayLabel(
  MaterialLocalizations localizations,
  DateTime date,
  DateTime now,
) {
  final yesterday = DateTime(now.year, now.month, now.day - 1);
  if (DateUtils.isSameDay(date, now)) return 'Today';
  if (DateUtils.isSameDay(date, yesterday)) return 'Yesterday';
  if (date.year == now.year) return localizations.formatMediumDate(date);
  return localizations.formatShortDate(date);
}
