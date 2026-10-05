import 'dart:developer' as developer;

import 'package:echonotes/features/recording/data/device_channel.dart';
import 'package:echonotes/features/recording/domain/storage_space.dart';

/// Free space as the phone reports it, through [deviceChannel].
///
/// On iOS that's the space available for things the user asked for, which
/// counts files the phone can clear by itself.
class ChannelStorageSpace implements StorageSpace {
  @override
  Future<int?> freeBytes() async {
    try {
      return await deviceChannel.invokeMethod<int>('freeBytes');
    } catch (error) {
      // Not knowing is no reason to stop someone recording.
      developer.log(
        "Couldn't read the free space",
        name: 'echonotes.recording',
        error: error,
      );
      return null;
    }
  }
}
