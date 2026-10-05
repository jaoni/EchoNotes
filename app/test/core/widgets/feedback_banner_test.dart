import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/widgets/feedback_banner.dart';

import '../../helpers/themed_app.dart';

void main() {
  testWidgets('shows its message with an icon', (tester) async {
    await tester.pumpWidget(
      themedComponent(
        const FeedbackBanner(
          tone: FeedbackTone.error,
          message: 'Upload failed',
        ),
      ),
    );

    expect(find.text('Upload failed'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('offers its action', (tester) async {
    var pressed = 0;
    await tester.pumpWidget(
      themedComponent(
        FeedbackBanner(
          tone: FeedbackTone.info,
          message: 'The phone may stop this recording.',
          actionLabel: 'Battery settings',
          onAction: () => pressed++,
        ),
      ),
    );

    await tester.tap(find.text('Battery settings'));

    expect(pressed, 1);
  });
}
