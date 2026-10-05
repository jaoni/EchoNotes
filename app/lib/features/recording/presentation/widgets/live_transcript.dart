import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/core/theme/app_motion.dart';
import 'package:echonotes/core/theme/app_radius.dart';
import 'package:echonotes/core/theme/app_spacing.dart';
import 'package:echonotes/core/theme/theme_context.dart';
import 'package:echonotes/features/recording/presentation/recording_controller.dart';

/// The rough live transcript while recording, in a card below its
/// `LiveTranscriptHeader`. Scrolls itself to the newest words, unless the
/// user has scrolled up to reread something.
///
/// Needs a bounded height from its parent.
class LiveTranscript extends ConsumerStatefulWidget {
  const LiveTranscript({super.key});

  @override
  ConsumerState<LiveTranscript> createState() => _LiveTranscriptState();
}

class _LiveTranscriptState extends ConsumerState<LiveTranscript> {
  /// How close to the end still counts as following along.
  static const _followSlack = 48.0;

  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _followNewWords() {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels < position.maxScrollExtent - _followSlack) return;

    // Scroll once the new words have been laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(
          end,
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    ref.listen(
      recordingControllerProvider.select((state) => state.transcript),
      (previous, next) => _followNewWords(),
    );
    final transcript = ref.watch(
      recordingControllerProvider.select((state) => state.transcript),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border.all(color: colors.border),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.lg)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          controller: _scroll,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              // The live preview arrives in Step 6. Until then, the
              // transcript stays empty.
              transcript.isEmpty
                  ? 'The live preview is coming soon. Everything you say is '
                        'still recorded, and the full transcript comes after '
                        'you stop.'
                  : transcript,
              style: context.textTheme.bodyLarge?.copyWith(
                color: transcript.isEmpty
                    ? colors.textSecondary
                    : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
