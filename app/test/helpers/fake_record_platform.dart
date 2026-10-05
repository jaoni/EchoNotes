import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:record_platform_interface/record_platform_interface.dart';

/// Stands in for the `record` package's Android and iOS code, so the real
/// recorder service can be tested. Install it with
/// `RecordPlatform.instance = FakeRecordPlatform()`.
///
/// Only streaming is supported, like the app uses.
class FakeRecordPlatform extends Fake implements RecordPlatform {
  final _states = StreamController<RecordState>.broadcast();
  StreamController<Uint8List>? _audio;

  /// The config of the last start.
  RecordConfig? config;
  var starts = 0;
  var stops = 0;

  /// When set, starting throws this.
  Object? startError;

  bool get isStreaming => _audio != null;

  /// Pretends the encoder sent [bytes].
  void sendAudio(Uint8List bytes) => _audio!.add(bytes);

  /// Pretends the phone changed the recorder's state, as for an
  /// interruption.
  void sendState(RecordState state) => _states.add(state);

  /// Pretends the audio stopped without a word, as on iOS when headphones
  /// connect.
  void goSilent() {
    unawaited(_audio?.close());
  }

  @override
  Future<void> create(String recorderId) async {}

  @override
  Future<Stream<Uint8List>> startStream(
    String recorderId,
    RecordConfig config,
  ) async {
    if (startError case final error?) throw error;
    starts++;
    this.config = config;
    final audio = StreamController<Uint8List>();
    _audio = audio;
    _states.add(RecordState.record);
    return audio.stream;
  }

  @override
  Future<String?> stop(String recorderId) async {
    stops++;
    final audio = _audio;
    _audio = null;
    await audio?.close();
    _states.add(RecordState.stop);
    return null;
  }

  @override
  Future<bool> isRecording(String recorderId) async => _audio != null;

  @override
  Future<Amplitude> getAmplitude(String recorderId) async {
    return Amplitude(current: -20, max: -10);
  }

  @override
  Stream<RecordState> onStateChanged(String recorderId) => _states.stream;

  @override
  Future<void> dispose(String recorderId) async {
    await _audio?.close();
  }
}
