import 'package:material_ui/material_ui.dart';

import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/app_theme.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/buttons_section.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/colors_section.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/dialogs_section.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/note_card_section.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/record_button_demo.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/spacing_section.dart';
import 'package:echonotes/features/design_preview/presentation/widgets/typography_section.dart';

/// Every color, text style and key component on one screen, so the whole
/// design can be reviewed in one place. It can switch between light and dark
/// without changing the phone's setting.
///
/// Debug builds only: open it with the palette button on the home screen.
class DesignPreviewScreen extends StatefulWidget {
  const DesignPreviewScreen({super.key});

  /// Its path under the home route, and the location to go to.
  static const routePath = 'design';
  static const location = '/design';

  @override
  State<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends State<DesignPreviewScreen> {
  ThemeMode _mode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    final brightness = switch (_mode) {
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
    };

    return AnimatedTheme(
      data: brightness == Brightness.dark ? AppTheme.dark : AppTheme.light,
      child: Scaffold(
        appBar: AppBar(title: const Text('Design preview')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.sm,
            AppSpacing.page,
            AppSpacing.xxxl,
          ),
          children: [
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {_mode},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.single);
              },
            ),
            const ColorsSection(),
            const TypographySection(),
            const ButtonsSection(),
            const NoteCardSection(),
            const DialogsSection(),
            const RecordButtonDemo(),
            const SpacingSection(),
          ],
        ),
      ),
    );
  }
}
