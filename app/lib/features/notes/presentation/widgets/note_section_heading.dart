import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';

/// The heading above a part of a note, such as "Summary".
class NoteSectionHeading extends StatelessWidget {
  const NoteSectionHeading({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.xxl,
        bottom: AppSpacing.md,
      ),
      child: Semantics(
        header: true,
        child: Text(title, style: context.textTheme.titleLarge),
      ),
    );
  }
}
