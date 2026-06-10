import 'dart:isolate';

enum PdfWorkerCommandType {
  openDocument,
  closeWorker,
  getImage,
  none;

  static PdfWorkerCommandType getStringType(String name) {
    if (name == closeWorker.name) return closeWorker;
    if (name == getImage.name) return getImage;
    if (name == openDocument.name) return openDocument;
    return none;
  }

  static PdfWorkerCommandType getMapType(Map<String, dynamic> map) {
    final name = map['command'] ?? '';
    if (name == closeWorker.name) return closeWorker;
    if (name == getImage.name) return getImage;
    if (name == openDocument.name) return openDocument;
    return none;
  }
}

class PdfBackgroundWorkerResult<T> {
  final bool isError;
  final String? message;
  final T result;
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
      result: map['result'] as T,
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
