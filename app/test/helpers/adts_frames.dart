import 'dart:typed_data';

/// One ADTS frame of mono AAC at 16 kHz (64 ms of audio), with
/// [audioBytes] of made-up audio after its 7-byte header.
Uint8List adtsFrame({int audioBytes = 20}) {
  final length = audioBytes + 7;
  return Uint8List.fromList([
    0xFF,
    0xF1, // MPEG-4, no checksum
    (1 << 6) | (8 << 2), // AAC LC, 16 kHz
    (1 << 6) | (length >> 11), // mono
    (length >> 3) & 0xFF,
    ((length & 0x07) << 5) | 0x1F,
    0xFC, // one block of 1024 samples
    ...List.filled(audioBytes, 0x21),
  ]);
}

/// [count] frames in a row: [count] × 64 ms of audio.
Uint8List adtsFrames(int count) {
  return Uint8List.fromList([for (var i = 0; i < count; i++) ...adtsFrame()]);
}
