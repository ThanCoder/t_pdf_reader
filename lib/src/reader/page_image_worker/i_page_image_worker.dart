import 'dart:typed_data';

import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';
import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';
import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:than_pdf_engine/core/types/result.dart';

part 'page_image_worker_single_thread.dart';
part 'page_image_worker_multi_thread.dart';

enum IPageImageWorkerType {
  singleThread,
  multiThread;

  String get label {
    if (this == multiThread) {
      return 'Multiple Thread';
    }
    return 'Single Thread';
  }

  IPageImageWorker createThread() {
    if (this == multiThread) {
      return PageImageWorkerMultiThread(.multiThread);
    }
    return PageImageWorkerSingleThread(.singleThread);
  }

  static IPageImageWorkerType fromValue(String val) {
    return values.firstWhere((e) => e.name == val, orElse: () => .singleThread);
  }
}

sealed class IPageImageWorker {
  final IPageImageWorkerType type;
  const IPageImageWorker(this.type);

  Future<Result<bool, PdfReaderWorkerOpenErrorResult>> open(String path);
  Future<void> close();

  Future<Result<Uint8List, String>> getImageLowQuality(
    int pageIndex, {
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 20,
    PageRenderImageType renderImageType = .jpg,
  });
  Future<Result<Uint8List, String>> getImageHighQuality(
    int pageIndex, {
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 100,
    PageRenderImageType renderImageType = .jpg,
  });

  Future<Result<List<PageSize>, String>> getAllPageSizes();
}
