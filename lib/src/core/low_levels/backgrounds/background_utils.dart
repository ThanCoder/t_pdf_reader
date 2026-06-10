part of 'pdf_background_document.dart';

void _pdfBackgroundWorker((SendPort, String, String?) args) async {
  final receivePort = ReceivePort();
  final mainSendPort = args.$1;
  final filepath = args.$2;
  final password = args.$3;

  final pdf = getPdfium();
  pdf.FPDF_InitLibrary();
  String? openError;

  final dom = PdfDocument();

  try {
    dom.openFile(filepath, password: password);
  } catch (e) {
    openError = e.toString();
  }
  //send background sendport
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) {
    if (message is Map) {
      final sender = SendPdfBackgroundWorkerSender.fromMap(
        message as Map<String, dynamic>,
      );
      // if (openError != null || sender.command != .closeWorker) {
      //   sender.replySendPort?.send(
      //     PdfBackgroundWorkerResult<String>(
      //       isError: false,
      //       result: openError!,
      //     ).toMap(),
      //   );
      //   return;
      // }
      if (sender.command == .getImage) {
        final pageIndex = message['pageIndex'] ?? 0;
        final quality = message['quality'] ?? 100;
        final page = dom.getPage(pageIndex);

        final data = page.getPdfImageTransferableTypedDataAsync(
          quality: quality,
          renderImageErrorCallback: (error) {
            sender.replySendPort?.send(
              PdfBackgroundWorkerResult(
                isError: true,
                result: null,
                message: error,
              ).toMap(),
            );
          },
        );

        if (data != null) {
          sender.replySendPort?.send(
            PdfBackgroundWorkerResult<TransferableTypedData>(
              isError: false,
              result: data,
            ).toMap(),
          );
          return;
        }
        // data မရှိရင် error ပဲ
        sender.replySendPort?.send(
          PdfBackgroundWorkerResult(
            isError: true,
            result: null,
            message: 'data is null',
          ).toMap(),
        );
      }

      // close
      if (sender.command == .closeWorker) {
        dom.close();
      }
    }
  });
}
