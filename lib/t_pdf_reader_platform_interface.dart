import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 't_pdf_reader_method_channel.dart';

abstract class TPdfReaderPlatform extends PlatformInterface {
  /// Constructs a TPdfReaderPlatform.
  TPdfReaderPlatform() : super(token: _token);

  static final Object _token = Object();

  static TPdfReaderPlatform _instance = MethodChannelTPdfReader();

  /// The default instance of [TPdfReaderPlatform] to use.
  ///
  /// Defaults to [MethodChannelTPdfReader].
  static TPdfReaderPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TPdfReaderPlatform] when
  /// they register themselves.
  static set instance(TPdfReaderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
