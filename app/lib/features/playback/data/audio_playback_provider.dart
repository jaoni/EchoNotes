import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/playback/data/just_audio_playback.dart';
import 'package:echonotes/features/playback/domain/audio_playback.dart';

/// Makes a new player. Each open note gets its own, and disposes it when
/// it closes. Tests override this with fakes.
final audioPlaybackFactoryProvider = Provider<AudioPlayback Function()>((ref) {
  return JustAudioPlayback.new;
});
