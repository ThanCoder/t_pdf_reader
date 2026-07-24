import 'package:t_pdf_reader/src/interfaces/i_pdf_platform_controller.dart';
import 'package:t_pdf_reader/src/state/reader_state.dart';

abstract class IPdfReader {
  ReaderState get state;

  IPdfPlatformController get pdfPlatformController;
  IPdfContext get pdfContext;
}
