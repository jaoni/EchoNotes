import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/preview_section.dart';

/// Every button style, plus a text field in its normal and error states.
class ButtonsSection extends StatelessWidget {
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewSection(
      title: 'Buttons and fields',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.mic_rounded),
                label: const Text('Record'),
              ),
              FilledButton.tonal(onPressed: () {}, child: const Text('Tonal')),
              OutlinedButton(onPressed: () {}, child: const Text('Outlined')),
              TextButton(onPressed: () {}, child: const Text('Text')),
              const FilledButton(onPressed: null, child: Text('Disabled')),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: 'Untitled note',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Title',
              errorText: 'Give the note a title.',
            ),
          ),
        ],
      ),
    );
  }
}
