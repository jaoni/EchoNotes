import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/widgets/record_button.dart';

import '../../helpers/themed_app.dart';

void main() {
  testWidgets('starts idle and reports taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      themedComponent(
        RecordButton(isRecording: false, onPressed: () => taps++),
      ),
    );

    expect(find.bySemanticsLabel('Start recording'), findsOneWidget);
    await tester.tap(find.byType(RecordButton));
    expect(taps, 1);
  });

  testWidgets('offers stop and animates the ripples while recording', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedComponent(
        RecordButton(isRecording: true, level: 0.5, onPressed: () {}),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.bySemanticsLabel('Stop recording'), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('keeps the ripples still when the user asks for less motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedComponent(
        RecordButton(isRecording: true, level: 0.5, onPressed: () {}),
        reduceMotion: true,
      ),
    );
    // Would time out if the ripples kept looping.
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Stop recording'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('still offers stop while paused, with the ripples at rest', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedComponent(
        RecordButton(isRecording: true, isPaused: true, onPressed: () {}),
      ),
    );
    // Would time out if the ripples kept looping.
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Stop recording'), findsOneWidget);
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('lets taps on the ripple area reach what is behind it', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      themedApp(
        Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                ),
              ),
              Center(
                child: RecordButton(
                  isRecording: true,
                  level: 1,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Just inside the ripple area, well outside the button itself.
    final center = tester.getCenter(find.byType(RecordButton));
    await tester.tapAt(center.translate(RecordButton.footprint / 2 - 2, 0));
    expect(taps, 1);
  });

  testWidgets('is disabled without onPressed', (tester) async {
    await tester.pumpWidget(
      themedComponent(const RecordButton(isRecording: false, onPressed: null)),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Start recording')),
      isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
    );
  });
}
