import 'dart:io';
import 'dart:typed_data';

/// AAC audio in ADTS frames: the format recordings are saved in.
///
/// Every frame starts with a short header that says how long the frame is
/// and how much audio it holds: 1024 samples, which is 64 ms at 16 kHz. A
/// frame can be read without the rest of the file, so a recording cut off
/// mid-write is still readable up to its last whole frame, and a file can
/// be split at any frame.
///
/// Groq Whisper doesn't take `.aac` files, so the upload step repackages
/// the frames as `.m4a`, without re-encoding them.
class AdtsHeader {
  const AdtsHeader._({
    required this.headerLength,
    required this.frameLength,
    required this.sampleRate,
    required this.sampleCount,
  });

  /// The shortest header: without a checksum.
  static const minLength = 7;

  /// Frames whose audio part is this short can't hold any sound. Android
  /// sends the encoder's 2-byte setup data this way before the first real
  /// frame, and decoders fail on it.
  static const _minimumAudioBytes = 3;

  /// Samples per second, by the index the header stores.
  static const _sampleRates = [
    96000,
    88200,
    64000,
    48000,
    44100,
    32000,
    24000,
    22050,
    16000,
    12000,
    11025,
    8000,
    7350,
  ];

  /// The header at [offset] in [bytes], or null when there isn't a valid
  /// one there or [bytes] ends too soon to tell.
  static AdtsHeader? parse(Uint8List bytes, int offset) {
    if (bytes.length - offset < minLength) return null;
    final b1 = bytes[offset + 1];
    // 12 bits of sync word, then a layer that is always 0.
    if (bytes[offset] != 0xFF || b1 & 0xF6 != 0xF0) return null;

    final rateIndex = (bytes[offset + 2] >> 2) & 0x0F;
    if (rateIndex >= _sampleRates.length) return null;
    final headerLength = b1 & 0x01 == 1 ? 7 : 9;
    final frameLength =
        ((bytes[offset + 3] & 0x03) << 11) |
        (bytes[offset + 4] << 3) |
        (bytes[offset + 5] >> 5);
    if (frameLength < headerLength) return null;
    final blocks = (bytes[offset + 6] & 0x03) + 1;

    return AdtsHeader._(
      headerLength: headerLength,
      frameLength: frameLength,
      sampleRate: _sampleRates[rateIndex],
      sampleCount: blocks * 1024,
    );
  }

  final int headerLength;

  /// The whole frame, header included, in bytes.
  final int frameLength;
  final int sampleRate;
  final int sampleCount;

  /// How much audio the frame holds.
  Duration get duration {
    return Duration(microseconds: sampleCount * 1000000 ~/ sampleRate);
  }

  bool get holdsAudio => frameLength - headerLength >= _minimumAudioBytes;
}

/// Cuts a stream of bytes into whole ADTS frames, however the bytes arrive.
///
/// Leaves out frames that hold no audio, and skips bytes that aren't part
/// of any frame until the next frame starts.
class AdtsFrameSplitter {
  var _pending = Uint8List(0);
  var _consumed = 0;

  /// The frames that [bytes] complete, in order, with how much audio they
  /// hold together. A frame that isn't whole yet waits for the next bytes.
  AdtsFrames add(Uint8List bytes) {
    final data = _pending.isEmpty
        ? bytes
        : (BytesBuilder(copy: false)
                ..add(_pending)
                ..add(bytes))
              .takeBytes();
    final frames = BytesBuilder(copy: false);
    var duration = Duration.zero;
    var offset = 0;

    while (data.length - offset >= AdtsHeader.minLength) {
      final header = AdtsHeader.parse(data, offset);
      if (header == null) {
        offset++;
        continue;
      }
      if (data.length - offset < header.frameLength) break;
      if (header.holdsAudio) {
        frames.add(
          Uint8List.sublistView(data, offset, offset + header.frameLength),
        );
        duration += header.duration;
      }
      offset += header.frameLength;
    }

    _consumed += offset;
    _pending = Uint8List.fromList(Uint8List.sublistView(data, offset));
    return AdtsFrames(frames.takeBytes(), duration);
  }

  /// How many bytes have been added, up to the end of the last whole frame.
  int get consumedBytes => _consumed;
}

/// Whole frames, one after the other, and how much audio they hold.
class AdtsFrames {
  const AdtsFrames(this.bytes, this.duration);

  final Uint8List bytes;
  final Duration duration;
}

/// Makes a recording cut off mid-write safe to use, and returns how much
/// audio it holds.
///
/// Anything after the last whole frame, such as a half-written frame, is
/// cut off. A missing or empty file holds no audio.
Future<Duration> repairAdtsFile(String path) async {
  const blockSize = 256 * 1024;
  final file = File(path);
  if (!await file.exists()) return Duration.zero;

  final reader = await file.open();
  final splitter = AdtsFrameSplitter();
  var duration = Duration.zero;
  final int length;
  try {
    length = await reader.length();
    while (true) {
      final block = await reader.read(blockSize);
      if (block.isEmpty) break;
      duration += splitter.add(block).duration;
    }
  } finally {
    await reader.close();
  }

  if (splitter.consumedBytes < length) {
    final writer = await file.open(mode: FileMode.append);
    try {
      await writer.truncate(splitter.consumedBytes);
    } finally {
      await writer.close();
    }
  }
  return duration;
}
