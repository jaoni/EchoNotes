import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';

/// A titled block on the design preview screen.
class PreviewSection extends StatelessWidget {
  const PreviewSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: context.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
