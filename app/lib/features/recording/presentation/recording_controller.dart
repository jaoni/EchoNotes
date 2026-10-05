import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:echonotes/features/notes/data/audio_file_store_provider.dart';
import 'package:echonotes/features/notes/data/notes_repository_provider.dart';
import 'package:echonotes/features/notes/domain/audio_file_store.dart';
import 'package:echonotes/features/notes/domain/note.dart';
import 'package:echonotes/features/notes/domain/notes_repository.dart';
import 'package:echonotes/features/recording/data/recording_recovery_provider.dart';
import 'package:echonotes/features/recording/data/recording_service_providers.dart';
import 'package:echonotes/features/recording/domain/audio_recorder_service.dart';
import 'package:echonotes/features/recording/domain/background_recording.dart';
import 'package:echonotes/features/recording/domain/microphone_permission.dart';
import 'package:echonotes/features/recording/domain/recording_limits.dart';
import 'package:echonotes/features/recording/domain/recording_preferences.dart';
import 'package:echonotes/features/recording/domain/storage_space.dart';
import 'package:echonotes/features/recording/presentation/recording_ending_message.dart';
import 'package:echonotes/features/recording/presentation/recording_state.dart';

/// Runs one recording, from opening the recording screen until it's saved
/// or thrown away. Ends when the screen closes.
final recordingControllerProvider =
    NotifierProvider.autoDispose<RecordingController, RecordingState>(
      RecordingController.new,
    );

/// Starts recording as soon as it can, then pauses, resumes, stops and
/// discards.
///
/// Before the first recording ever, it shows the reminder to tell people
/// they're being recorded. Then it needs microphone access and enough free
/// space, and asks once to show the recording notification. The note is
/// made the moment recording starts, so a recording cut off by a crash is
/// recovered on the next launch.
///
/// Recording carries on in the background and with the screen locked:
/// [BackgroundRecording] follows every change of phase (see
/// [_followInBackground]), and its notification's buttons pause, resume and
/// stop.
class RecordingController extends Notifier<RecordingState> {
  /// How many recent levels the waveform keeps.
  static const _maxLevels = 64;

  /// The level drawn as silence, in dBFS. 0 dBFS is drawn full height.
  static const _quietestLevel = -60.0;

  /// Readings at or below this are digital silence: no quiet room is this
  /// quiet, so something else has the microphone.
  static const _silentLevel = -120.0;

  /// About five seconds of levels.
  static const _silentReadingsBeforeNotice = 50;

  late AudioRecorderService _recorder;
  late NotesRepository _notes;
  late AudioFileStore _audioFiles;
  late MicrophonePermission _permission;
  late StorageSpace _storage;
  late BackgroundRecording _background;
  late RecordingPreferences _preferences;
  late RecordingLimits _limits;
  late AppLifecycleListener _lifecycle;
  final _subscriptions = <StreamSubscription<Object>>[];

  /// The latest state, still readable while the controller is disposed.
  var _latest = const RecordingState();
  var _silentReadings = 0;

  /// Set while pausing or resuming, so a double tap does it once.
  var _switching = false;

  /// Whether the background recording was started, and not yet stopped.
  var _inBackgroundService = false;

  /// Whether the preferences say this recording runs in the background.
  var _rememberedInBackground = false;

  @override
  RecordingState build() {
    // Read once: a running recording must never start over because a
    // service was rebuilt, as when the database is reopened. The recorder
    // is watched only to keep it alive until this controller goes.
    _recorder = ref.watch(audioRecorderServiceProvider);
    _notes = ref.read(notesRepositoryProvider);
    _audioFiles = ref.read(audioFileStoreProvider);
    _permission = ref.read(microphonePermissionProvider);
    _storage = ref.read(storageSpaceProvider);
    _background = ref.read(backgroundRecordingProvider);
    _preferences = ref.read(recordingPreferencesProvider);
    _limits = ref.read(recordingLimitsProvider);

    _subscriptions.addAll([
      _recorder.recordedLength.listen(_onLength),
      _recorder.levels.listen(_onLevel),
      _recorder.events.listen(_onRecorderEvent),
      _background.events.listen(_onBackgroundEvent),
    ]);
    _lifecycle = AppLifecycleListener(
      onHide: _onAppHidden,
      onShow: _onAppShown,
      onResume: _onAppResumed,
    );
    listenSelf((previous, next) {
      _latest = next;
      if (previous?.phase != next.phase) _followInBackground(next);
    });
    ref.onDispose(_onDispose);

    unawaited(_prepare());
    return const RecordingState();
  }

  /// Carries on after the one-time reminder, which won't show again.
  Future<void> continueAfterReminder() async {
    if (state.phase != RecordingPhase.reminder) return;
    state = state.copyWith(phase: RecordingPhase.preparing);
    try {
      await _preferences.markConsentReminderSeen();
    } catch (error) {
      // It shows once more next time, which is better than never.
      _log("Couldn't remember that the reminder was seen", error);
    }
    await _checkAccessAndStart(ask: true);
  }

  /// Tries again after microphone access was refused, there wasn't enough
  /// space, or the microphone wouldn't start.
  Future<void> retry() async {
    const retryable = {
      RecordingPhase.permissionDenied,
      RecordingPhase.notEnoughSpace,
      RecordingPhase.couldNotStart,
    };
    if (!retryable.contains(state.phase)) return;
    state = state.copyWith(phase: RecordingPhase.preparing);
    await _checkAccessAndStart(ask: true);
  }

  /// Opens the phone's settings for this app. Coming back checks the
  /// microphone access again.
  Future<void> openSettings() async {
    try {
      await _permission.openSettings();
    } catch (error) {
      _log("Couldn't open the settings", error);
    }
  }

  /// Opens the settings where EchoNotes' battery use can be changed, so the
  /// phone doesn't stop it in the background.
  Future<void> openBatterySettings() async {
    try {
      await _background.openBatterySettings();
    } catch (error) {
      _log("Couldn't open the battery settings", error);
    }
  }

  Future<void> pause() async {
    if (state.phase != RecordingPhase.recording || _switching) return;
    _switching = true;
    _silentReadings = 0;
    state = state
        .copyWith(phase: RecordingPhase.paused)
        .withNotices(
          remove: {RecordingNotice.noSound, RecordingNotice.resumeFailed},
        );
    try {
      await _recorder.pause();
    } catch (error) {
      _log("Couldn't pause", error);
    } finally {
      _switching = false;
    }
  }

  Future<void> resume() async {
    if (!state.canResume || _switching) return;
    _switching = true;
    try {
      await _recorder.resume();
      // Stopped or discarded meanwhile.
      if (!ref.mounted || state.phase != RecordingPhase.paused) return;
      state = state
          .copyWith(phase: RecordingPhase.recording)
          .withNotices(
            remove: {RecordingNotice.interrupted, RecordingNotice.resumeFailed},
          );
    } catch (error) {
      _log("Couldn't resume", error);
      if (ref.mounted) {
        state = state.withNotices(add: {RecordingNotice.resumeFailed});
      }
    } finally {
      _switching = false;
    }
  }

  /// Stops and saves the recording as a note, which goes on to processing.
  ///
  /// If saving fails, the recording stays paused and safe: stopping again
  /// tries again, and if the app closes first, recovery saves it.
  Future<void> stop({RecordingEnding ending = RecordingEnding.byUser}) async {
    final phase = state.phase;
    if (phase != RecordingPhase.recording && phase != RecordingPhase.paused) {
      return;
    }
    final noteId = state.noteId!;
    state = state
        .copyWith(phase: RecordingPhase.saving, ending: ending)
        .withNotices(remove: {RecordingNotice.saveFailed});

    try {
      await _recorder.stop();
    } catch (error) {
      // What was written is in the file, so save it anyway.
      _log("Couldn't stop the recorder", error);
    }
    try {
      // Read after stopping: the last audio arrives while it stops.
      await _notes.finishRecording(noteId, _latest.elapsed);
      if (ref.mounted) state = state.copyWith(phase: RecordingPhase.stopped);
    } catch (error) {
      _log("Couldn't save the recording", error);
      if (ref.mounted) {
        state = state
            .copyWith(phase: RecordingPhase.paused)
            .withNotices(add: {RecordingNotice.saveFailed});
      }
    }
  }

  /// Throws the recording away: its note and its audio.
  Future<void> discard() async {
    final noteId = state.noteId;
    if (!state.phase.hasAudio || state.phase == RecordingPhase.saving) return;
    try {
      await _recorder.stop();
    } catch (error) {
      _log("Couldn't stop the recorder", error);
    }
    if (noteId != null) await _deleteNote(noteId);
    if (ref.mounted) state = state.copyWith(phase: RecordingPhase.discarded);
  }

  Future<void> _prepare() async {
    try {
      // Never at the same time as a recording, so it can't touch this one.
      await ref.read(recordingRecoveryProvider.future);
    } catch (error) {
      _log("Couldn't recover earlier recordings", error);
    }
    if (!ref.mounted) return;

    var seenReminder = false;
    try {
      seenReminder = await _preferences.hasSeenConsentReminder();
    } catch (error) {
      _log("Couldn't check whether the reminder was seen", error);
    }
    if (!ref.mounted) return;
    if (!seenReminder) {
      state = state.copyWith(phase: RecordingPhase.reminder);
      return;
    }
    await _checkAccessAndStart(ask: true);
  }

  /// Checks microphone access, asking for it when [ask], then the free
  /// space, then starts.
  Future<void> _checkAccessAndStart({required bool ask}) async {
    var access = MicrophoneAccess.denied;
    try {
      access = await _permission.check();
      if (access != MicrophoneAccess.granted && ask) {
        access = await _permission.request();
      }
    } catch (error) {
      _log("Couldn't check microphone access", error);
    }
    if (!ref.mounted) return;
    switch (access) {
      case MicrophoneAccess.denied:
        state = state.copyWith(phase: RecordingPhase.permissionDenied);
        return;
      case MicrophoneAccess.blocked:
        state = state.copyWith(phase: RecordingPhase.permissionBlocked);
        return;
      case MicrophoneAccess.granted:
        break;
    }
    await _askToShowNotificationsOnce();
    if (!ref.mounted) return;

    final freeBytes = await _storage.freeBytes();
    if (!ref.mounted) return;
    Duration? spaceLeft;
    if (freeBytes != null) {
      final usableBytes = freeBytes - _limits.minimumFreeBytes;
      if (usableBytes <= 0) {
        state = state.copyWith(phase: RecordingPhase.notEnoughSpace);
        return;
      }
      final seconds = usableBytes ~/ _recorder.bytesPerSecond;
      if (seconds < _limits.maxLength.inSeconds) {
        spaceLeft = Duration(seconds: seconds);
      }
    }
    await _start(spaceLeft: spaceLeft);
  }

  Future<void> _start({Duration? spaceLeft}) async {
    final Note note;
    try {
      note = await _notes.startRecording(
        recordedAt: DateTime.now(),
        audioFileExtension: _recorder.fileExtension,
      );
    } catch (error) {
      _log("Couldn't make the recording's note", error);
      if (ref.mounted) {
        state = state.copyWith(phase: RecordingPhase.couldNotStart);
      }
      return;
    }

    final bool limitedInBackground;
    try {
      if (!ref.mounted) throw StateError('The screen closed.');
      final path = await _audioFiles.pathForNewRecording(note.audioFileName!);
      if (!ref.mounted) throw StateError('The screen closed.');
      await _recorder.start(path);
      // Now, while the app is on screen, as Android requires.
      limitedInBackground = await _startInBackground();
      if (!ref.mounted) throw StateError('The screen closed.');
    } catch (error) {
      _log("Couldn't start recording", error);
      // Nothing worth keeping was recorded.
      try {
        await _recorder.stop();
      } catch (error) {
        _log("Couldn't stop the recorder", error);
      }
      await _stopInBackground();
      await _deleteNote(note.id);
      if (ref.mounted) {
        state = state.copyWith(phase: RecordingPhase.couldNotStart);
      }
      return;
    }

    state = state
        .copyWith(
          phase: RecordingPhase.recording,
          noteId: note.id,
          spaceLeft: spaceLeft,
        )
        .withNotices(
          add: {
            if (spaceLeft != null) RecordingNotice.lowSpace,
            if (limitedInBackground) RecordingNotice.limitedInBackground,
          },
        );
    // Left while the recording started: remember it, as on leaving.
    if (!_isAppVisible) _rememberInBackground(note.id);
  }

  /// Starts keeping the recording going in the background, and says
  /// whether the phone may stop it there anyway.
  Future<bool> _startInBackground() async {
    _inBackgroundService = true;
    try {
      await _background.start();
    } catch (error) {
      _log("Couldn't keep the recording going in the background", error);
      return true;
    }
    try {
      return await _background.isLimitedByBattery();
    } catch (error) {
      _log("Couldn't check the battery settings", error);
      return false;
    }
  }

  /// Keeps the background recording in step with the recording, whichever
  /// way the phase changed: running while recording, paused while paused,
  /// stopped from saving on. So the phone is kept awake only while
  /// recording, whatever stopped or paused it.
  void _followInBackground(RecordingState next) {
    switch (next.phase) {
      case RecordingPhase.recording || RecordingPhase.paused:
        if (!_inBackgroundService) return;
        unawaited(
          _background
              .update(
                isPaused: next.phase == RecordingPhase.paused,
                elapsed: next.elapsed,
              )
              .catchError(
                (Object error) =>
                    _log("Couldn't update the notification", error),
              ),
        );
      case RecordingPhase.saving ||
          RecordingPhase.stopped ||
          RecordingPhase.discarded:
        final message = _isAppVisible || next.ending == null
            ? null
            : recordingEndingMessage(next.ending!, _limits.maxLength);
        unawaited(_stopInBackground(endedBecause: message));
        if (next.phase != RecordingPhase.saving) _forgetInBackground();
      case RecordingPhase.preparing ||
          RecordingPhase.reminder ||
          RecordingPhase.permissionDenied ||
          RecordingPhase.permissionBlocked ||
          RecordingPhase.notEnoughSpace ||
          RecordingPhase.couldNotStart:
        break;
    }
  }

  Future<void> _stopInBackground({String? endedBecause}) async {
    if (!_inBackgroundService) return;
    _inBackgroundService = false;
    try {
      await _background.stop(endedBecause: endedBecause);
    } catch (error) {
      _log("Couldn't stop the background recording", error);
    }
  }

  Future<void> _askToShowNotificationsOnce() async {
    try {
      if (await _preferences.hasAskedToShowNotifications()) return;
      // Never asked twice, even if asking fails.
      await _preferences.markAskedToShowNotifications();
      await _background.askToShowNotifications();
    } catch (error) {
      _log("Couldn't ask to show notifications", error);
    }
  }

  void _onLength(Duration length) {
    if (!state.phase.hasAudio) return;
    state = state
        .copyWith(elapsed: length)
        .withNotices(
          add: {if (length >= _limits.warnAt) RecordingNotice.limitSoon},
        );
    if (length >= _limits.maxLength) {
      unawaited(stop(ending: RecordingEnding.limitReached));
    }
  }

  void _onLevel(double decibels) {
    if (state.phase != RecordingPhase.recording) return;
    _silentReadings = decibels <= _silentLevel ? _silentReadings + 1 : 0;
    final level = ((decibels - _quietestLevel) / -_quietestLevel).clamp(
      0.0,
      1.0,
    );
    final levels = [...state.levels, level];
    final isSilent = _silentReadings >= _silentReadingsBeforeNotice;

    state = state
        .copyWith(
          levels: levels.length > _maxLevels
              ? levels.sublist(levels.length - _maxLevels)
              : levels,
        )
        .withNotices(
          add: {if (isSilent) RecordingNotice.noSound},
          remove: {if (!isSilent) RecordingNotice.noSound},
        );
  }

  /// A button pressed outside the app, or the phone refusing to keep the
  /// recording going there.
  void _onBackgroundEvent(BackgroundRecordingEvent event) {
    switch (event) {
      case BackgroundRecordingEvent.pause:
        unawaited(pause());
      case BackgroundRecordingEvent.resume:
        unawaited(resume());
      case BackgroundRecordingEvent.stop:
        unawaited(stop());
      case BackgroundRecordingEvent.unavailable:
        if (!state.phase.hasAudio) return;
        state = state.withNotices(add: {RecordingNotice.limitedInBackground});
    }
  }

  void _onRecorderEvent(RecorderEvent event) {
    switch (event) {
      case RecorderEvent.interrupted:
        if (state.phase != RecordingPhase.recording) return;
        _silentReadings = 0;
        state = state
            .copyWith(phase: RecordingPhase.paused)
            .withNotices(
              add: {RecordingNotice.interrupted},
              remove: {RecordingNotice.noSound},
            );
      case RecorderEvent.resumed:
        final wasInterrupted =
            state.phase == RecordingPhase.paused &&
            state.notices.contains(RecordingNotice.interrupted);
        if (!wasInterrupted) return;
        state = state
            .copyWith(phase: RecordingPhase.recording)
            .withNotices(remove: {RecordingNotice.interrupted});
      case RecorderEvent.outOfSpace:
        unawaited(stop(ending: RecordingEnding.outOfSpace));
      case RecorderEvent.writeFailed:
        unawaited(stop(ending: RecordingEnding.fileError));
    }
  }

  /// The recording carries on. If the phone kills the app while it can't
  /// be seen, recovery finds this note remembered, and can tell the user
  /// why the recording stopped.
  void _onAppHidden() {
    final noteId = state.noteId;
    final phase = state.phase;
    final isRunning =
        phase == RecordingPhase.recording || phase == RecordingPhase.paused;
    if (noteId != null && isRunning) _rememberInBackground(noteId);
  }

  void _onAppShown() {
    if (_rememberedInBackground) _forgetInBackground();
  }

  bool get _isAppVisible {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return lifecycle == null ||
        lifecycle == AppLifecycleState.resumed ||
        lifecycle == AppLifecycleState.inactive;
  }

  void _rememberInBackground(String noteId) {
    _rememberedInBackground = true;
    unawaited(_setNoteInBackground(noteId));
  }

  void _forgetInBackground() {
    if (!_rememberedInBackground) return;
    _rememberedInBackground = false;
    unawaited(_setNoteInBackground(null));
  }

  Future<void> _setNoteInBackground(String? noteId) async {
    try {
      await _preferences.setNoteRecordingInBackground(noteId);
    } catch (error) {
      _log("Couldn't remember the recording in the background", error);
    }
  }

  /// Back from the settings, perhaps with microphone access turned on.
  void _onAppResumed() {
    const waitingForAccess = {
      RecordingPhase.permissionDenied,
      RecordingPhase.permissionBlocked,
    };
    if (!waitingForAccess.contains(state.phase)) return;
    unawaited(_recheckAccess());
  }

  Future<void> _recheckAccess() async {
    final MicrophoneAccess access;
    try {
      access = await _permission.check();
    } catch (error) {
      _log("Couldn't check microphone access", error);
      return;
    }
    if (!ref.mounted || access != MicrophoneAccess.granted) return;
    state = state.copyWith(phase: RecordingPhase.preparing);
    await _checkAccessAndStart(ask: false);
  }

  void _onDispose() {
    _lifecycle.dispose();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_stopInBackground());
    _forgetInBackground();

    // Closed without stopping or discarding: keep what was recorded. The
    // recorder stops as it's disposed along with this controller.
    final latest = _latest;
    final phase = latest.phase;
    final noteId = latest.noteId;
    if (noteId != null &&
        (phase == RecordingPhase.recording || phase == RecordingPhase.paused)) {
      unawaited(
        _notes
            .finishRecording(noteId, latest.elapsed)
            .catchError(
              (Object error) => _log("Couldn't save the recording", error),
            ),
      );
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await _notes.deleteNote(noteId);
    } catch (error) {
      // It stays marked as recording, so the next launch recovers it.
      _log("Couldn't delete the recording's note", error);
    }
  }

  void _log(String message, Object error) {
    developer.log(message, name: 'echonotes.recording', error: error);
  }
}
