import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 't_pdf_reader_platform_interface.dart';

/// An implementation of [TPdfReaderPlatform] that uses method channels.
class MethodChannelTPdfReader extends TPdfReaderPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('t_pdf_reader');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }
}
