import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/core/widgets/note_card.dart';
import 'package:echonotes/core/widgets/status_badge.dart';
import 'package:echonotes/core/widgets/tag_chip.dart';

import '../../helpers/themed_app.dart';

void main() {
  testWidgets('shows the note and reports taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      themedComponent(
        NoteCard(
          title: 'Weekly sync',
          metadata: 'Today · 24 min',
          summary: 'We agreed to ship recording first.',
          tags: const ['design', 'planning'],
          onTap: () => tapped = true,
        ),
      ),
    );

    expect(find.text('Weekly sync'), findsOneWidget);
    expect(find.text('Today · 24 min'), findsOneWidget);
    expect(find.text('We agreed to ship recording first.'), findsOneWidget);
    expect(find.byType(TagChip), findsNWidgets(2));

    await tester.tap(find.byType(NoteCard));
    expect(tapped, isTrue);
  });

  testWidgets('leaves out the badge, summary and tags when there are none', (
    tester,
  ) async {
    await tester.pumpWidget(
      themedComponent(
        const NoteCard(title: 'Untitled recording', metadata: 'Just now'),
      ),
    );

    expect(find.text('Untitled recording'), findsOneWidget);
    expect(find.byType(StatusBadge), findsNothing);
    expect(find.byType(TagChip), findsNothing);
  });

  testWidgets('shows a status badge with an icon and words', (tester) async {
    await tester.pumpWidget(
      themedComponent(
        const NoteCard(
          title: 'New recording',
          metadata: 'Just now · 3 min',
          badge: StatusBadge(
            icon: Icons.error_outline_rounded,
            label: "Couldn't finish",
            tone: StatusBadgeTone.error,
          ),
        ),
      ),
    );

    expect(find.text("Couldn't finish"), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });

  testWidgets('keeps the summary to a short preview', (tester) async {
    await tester.pumpWidget(
      themedComponent(
        NoteCard(
          title: 'Lecture',
          metadata: 'Yesterday',
          summary: 'A very long summary. ' * 40,
        ),
      ),
    );

    final summary = tester.widget<Text>(find.textContaining('A very long'));
    expect(summary.maxLines, 2);
    expect(summary.overflow, TextOverflow.ellipsis);
  });

  testWidgets('reports long presses, and names them for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var longPressed = 0;
    await tester.pumpWidget(
      themedComponent(
        NoteCard(
          title: 'Weekly sync',
          metadata: 'Today',
          onTap: () {},
          onLongPress: () => longPressed++,
          longPressLabel: 'Delete note',
        ),
      ),
    );

    await tester.longPress(find.byType(NoteCard));
    expect(longPressed, 1);

    final node = tester.getSemantics(find.text('Weekly sync'));
    expect(
      node,
      isSemantics(
        customActions: [
          // Listed among the card's actions…
          const CustomSemanticsAction(label: 'Delete note'),
          // …and read out as the long press hint.
          const CustomSemanticsAction.overridingAction(
            hint: 'Delete note',
            action: SemanticsAction.longPress,
          ),
        ],
      ),
    );
    node.owner!.performAction(
      node.id,
      SemanticsAction.customAction,
      CustomSemanticsAction.getIdentifier(
        const CustomSemanticsAction(label: 'Delete note'),
      ),
    );
    expect(longPressed, 2);
    semantics.dispose();
  });
}
