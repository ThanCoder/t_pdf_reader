import 'dart:isolate';

import 'package:flutter/widgets.dart';
import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:t_pdf_reader/src/core/low_levels/backgrounds/background_types.dart';
import 'package:t_pdf_reader/src/core/low_levels/classes/pdf_document.dart';
import 'package:t_pdf_reader/src/core/low_levels/classes/types.dart';

part 'background_utils.dart';

class PdfBackgroundDocument {
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  late String _source;
  String? _password;
  String get source => _source;
  String? get password => _password;

  Future<void> openFile(String path, {String? password}) async {
    _source = path;
    _password = password;

    final receivePort = ReceivePort();
    _isolate = await Isolate.spawn(_pdfBackgroundWorker, (
      receivePort.sendPort,
      path,
      password,
    ));
    // set main send sport
    _isolateSendPort = await receivePort.first as SendPort;
  }

  Future<List<PdfSizedPage>> getSizedPage() async {
    return await getPagesAsyncFileSpeedUp(_source, password: _password);
  }

  Future<TransferableTypedData?> getPageImage(int pageIndex) async {
    if (_isolateSendPort == null) throw Exception('Need To Initilize');
    try {
      final receivePort = ReceivePort();

      _isolateSendPort?.send(
        SendPdfBackgroundWorkerSender(
          command: .getImage,
          replySendPort: receivePort.sendPort,
          extraMap: {'pageIndex': pageIndex},
        ).toMap(),
      );
      final map = await receivePort.first as Map<String, dynamic>;
      final result = PdfBackgroundWorkerResult<TransferableTypedData>.fromMap(
        map,
      );
      if (result.isError) {
        return null;
      }
      return result.result;
    } catch (e) {
      debugPrint('[PdfBackgroundDocument:getPageImage]: $e');
      return null;
    }
  }

  void close() {
    if (_isolateSendPort != null) {
      _isolateSendPort?.send(
        SendPdfBackgroundWorkerSender(
          command: .closeWorker,
          replySendPort: null,
        ).toMap(),
      );
    }
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
  }
}
