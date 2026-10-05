import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/notes/domain/key_point.dart';

/// One key point, with an accent bullet that lines up with its first line
/// at any text size.
class KeyPointTile extends StatelessWidget {
  const KeyPointTile({super.key, required this.point});

  final KeyPoint point;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          ExcludeSemantics(
            child: Text(
              '•',
              style: style?.copyWith(color: context.colors.accent),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(point.text, style: style)),
        ],
      ),
    );
  }
}
