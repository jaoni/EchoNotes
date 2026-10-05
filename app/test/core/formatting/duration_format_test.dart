import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/formatting/duration_format.dart';

void main() {
  group('formatClock', () {
    test('shows minutes and seconds under an hour', () {
      expect(formatClock(Duration.zero), '00:00');
      expect(formatClock(const Duration(seconds: 65)), '01:05');
      expect(formatClock(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('adds hours from an hour on', () {
      expect(
        formatClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  group('formatLength', () {
    test('uses seconds under a minute', () {
      expect(formatLength(const Duration(seconds: 45)), '45 sec');
    });

    test('rounds down to whole minutes', () {
      expect(formatLength(const Duration(minutes: 32, seconds: 40)), '32 min');
    });

    test('uses hours and minutes from an hour on', () {
      expect(formatLength(const Duration(hours: 1)), '1 h');
      expect(formatLength(const Duration(hours: 1, minutes: 5)), '1 h 5 min');
    });
  });
}
