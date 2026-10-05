/// Durations as a clock: "04:05", or "1:02:03" from an hour on. For timers,
/// transcript timestamps and the audio player.
String formatClock(Duration duration) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  final hours = duration.inHours;
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}

/// How long a recording is, in words: "45 sec", "32 min" or "1 h 5 min".
String formatLength(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (duration < const Duration(minutes: 1)) {
    return '${duration.inSeconds} sec';
  }
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours h';
  return '$hours h $minutes min';
}
