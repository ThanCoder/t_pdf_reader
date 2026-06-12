import 'dart:isolate';

enum PdfWorkerCommandType {
  openDocument,
  closeWorker,
  getImage,
  getRgbaImage,
  none;

  static PdfWorkerCommandType getMapType(Map<String, dynamic> map) {
    final name = map['command'] ?? '';
    return getStringType(name);
  }

  static PdfWorkerCommandType getStringType(String name) {
    if (name == closeWorker.name) return closeWorker;
    if (name == getImage.name) return getImage;
    if (name == getRgbaImage.name) return getRgbaImage;
    if (name == openDocument.name) return openDocument;
    return none;
  }
}

class PdfBackgroundWorkerResult<T> {
  final bool isError;
  final String? message;
  final T? result;
  const PdfBackgroundWorkerResult({
    required this.isError,
    this.message,
    required this.result,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isError': isError,
      'message': message,
      'result': result,
    };
  }

  factory PdfBackgroundWorkerResult.fromMap(Map<String, dynamic> map) {
    return PdfBackgroundWorkerResult<T>(
      isError: map['isError'] as bool,
      message: map['message'] != null ? map['message'] as String : null,
      result: map['result'] != null ? map['result'] as T : null,
    );
  }
}

class SendPdfBackgroundWorkerSender {
  final PdfWorkerCommandType command;
  final SendPort? replySendPort;
  final Map<String, dynamic>? extraMap;
  SendPdfBackgroundWorkerSender({
    required this.command,
    required this.replySendPort,
    this.extraMap,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'command': command.name,
      'replySendPort': replySendPort,
      ...?extraMap,
    };
  }

  factory SendPdfBackgroundWorkerSender.fromMap(Map<String, dynamic> map) {
    return SendPdfBackgroundWorkerSender(
      command: PdfWorkerCommandType.getStringType(map['command'] ?? ''),
      replySendPort: map['replySendPort'] as SendPort,
      extraMap: map,
    );
  }
}
