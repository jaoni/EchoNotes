import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/theme/app_motion.dart';
import 'package:echonotes/core/widgets/record_button.dart';
import 'package:echonotes/features/design_preview/presentation/design_preview_screen.dart';

import '../../../helpers/themed_app.dart';

void main() {
  // The screen's list; text fields inside it have scrollables of their own.
  final list = find.byType(Scrollable).first;

  testWidgets('shows every part of the design', (tester) async {
    await tester.pumpWidget(themedApp(const DesignPreviewScreen()));

    for (final title in [
      'Colors',
      'Typography',
      'Buttons and fields',
      'Note card',
      'Dialogs',
      'Record button',
      'Spacing and corners',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 300, scrollable: list);
      expect(find.text(title), findsOneWidget);
    }
  });

  testWidgets('opens the confirm dialog in the theme picked here', (
    tester,
  ) async {
    await tester.pumpWidget(themedApp(const DesignPreviewScreen()));
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final open = find.text('Show confirm dialog');
    await tester.scrollUntilVisible(open, 300, scrollable: list);

    await tester.tap(open);
    await tester.pumpAndSettle();

    final title = find.text('Delete this note?');
    expect(title, findsOneWidget);
    expect(Theme.of(tester.element(title)).brightness, Brightness.dark);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(title, findsNothing);
  });

  testWidgets('switches between light and dark', (tester) async {
    await tester.pumpWidget(themedApp(const DesignPreviewScreen()));
    Brightness brightness() =>
        Theme.of(tester.element(find.text('Design preview'))).brightness;

    expect(brightness(), Brightness.light);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.dark);

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(brightness(), Brightness.light);
  });

  testWidgets('plays and stops a pretend recording', (tester) async {
    await tester.pumpWidget(themedApp(const DesignPreviewScreen()));
    await tester.scrollUntilVisible(
      find.text('Record button'),
      300,
      scrollable: list,
    );
    final button = find.byType(RecordButton).first;
    final offersStop = find.descendant(
      of: button,
      matching: find.bySemanticsLabel('Stop recording'),
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    await tester.tap(button);
    await tester.pump(const Duration(seconds: 1));
    expect(offersStop, findsOneWidget);
    expect(
      find.text('Pretend recording. The rings follow a fake voice.'),
      findsOneWidget,
    );

    await tester.tap(button);
    await tester.pump(AppMotion.medium);
    expect(offersStop, findsNothing);
    expect(find.text('Tap to try a pretend recording.'), findsOneWidget);
  });
}
