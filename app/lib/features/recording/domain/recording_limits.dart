/// How long a recording may run, and how much room it needs.
class RecordingLimits {
  const RecordingLimits({
    this.maxLength = const Duration(hours: 3),
    this.warnBeforeEnd = const Duration(minutes: 5),
    this.minimumFreeBytes = 25 * 1000 * 1000,
  });

  /// Recording stops and is saved at this length.
  final Duration maxLength;

  /// How long before [maxLength] the user is warned.
  final Duration warnBeforeEnd;

  /// Room to always leave free on the phone. Recording won't start with
  /// less, since the phone and the notes database need space too.
  final int minimumFreeBytes;

  /// When the warning about the end appears.
  Duration get warnAt => maxLength - warnBeforeEnd;
}
