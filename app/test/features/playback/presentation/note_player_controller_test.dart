import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:echonotes/features/notes/data/audio_file_store_provider.dart';
import 'package:echonotes/features/playback/data/audio_playback_provider.dart';
import 'package:echonotes/features/playback/presentation/note_player_controller.dart';
import 'package:echonotes/features/playback/presentation/note_player_state.dart';

import '../../../helpers/fake_audio_file_store.dart';
import '../../../helpers/fake_audio_playback.dart';

void main() {
  const fileName = 'note.aac';

  late FakeAudioPlayback playback;
  late ProviderContainer container;

  Future<void> open() async {
    playback = FakeAudioPlayback();
    container = ProviderContainer(
      overrides: [
        audioFileStoreProvider.overrideWithValue(FakeAudioFileStore()),
        audioPlaybackFactoryProvider.overrideWithValue(() => playback),
      ],
    );
    addTearDown(container.dispose);
    container.listen(notePlayerProvider(fileName), (previous, next) {});
    await pumpEventQueue();
  }

  NotePlayerState state() => container.read(notePlayerProvider(fileName));
  NotePlayerController controller() {
    return container.read(notePlayerProvider(fileName).notifier);
  }

  test("opens the note's recording from the recordings folder", () async {
    await open();

    expect(playback.loadedPath, '/recordings/note.aac');
    expect(state().status, NotePlayerStatus.ready);
    expect(state().isPlaying, isFalse);
  });

  test('plays, pauses and follows the position', () async {
    await open();

    await controller().togglePlaying();
    await pumpEventQueue();
    expect(state().isPlaying, isTrue);

    playback.moveTo(const Duration(seconds: 12));
    await pumpEventQueue();
    expect(state().position, const Duration(seconds: 12));

    await controller().togglePlaying();
    await pumpEventQueue();
    expect(state().isPlaying, isFalse);
  });

  test('moves to a point in the recording', () async {
    await open();

    await controller().seek(const Duration(minutes: 2));

    expect(playback.seekedTo, const Duration(minutes: 2));
    expect(state().position, const Duration(minutes: 2));
  });

  test('says so when the recording cannot be opened', () async {
    playback = FakeAudioPlayback()..loadError = Exception('Unreadable');
    container = ProviderContainer(
      overrides: [
        audioFileStoreProvider.overrideWithValue(FakeAudioFileStore()),
        audioPlaybackFactoryProvider.overrideWithValue(() => playback),
      ],
    );
    addTearDown(container.dispose);
    container.listen(notePlayerProvider(fileName), (previous, next) {});
    await pumpEventQueue();

    expect(state().status, NotePlayerStatus.failed);
    await controller().togglePlaying();
    expect(playback.isPlaying, isFalse);
  });

  test('lets go of the player when the note closes', () async {
    await open();

    container.dispose();
    await pumpEventQueue();

    expect(playback.isDisposed, isTrue);
  });
}
