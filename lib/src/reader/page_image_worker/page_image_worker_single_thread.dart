part of 'i_page_image_worker.dart';

class PageImageWorkerSingleThread extends IPageImageWorker {
  final _worker = PdfReaderWorker();

  @override
  Future<Result<bool, PdfReaderWorkerOpenErrorResult>> open(String path) async {
    return await _worker.open(path);
  }

  @override
  Future<Result<Uint8List, String>> getImageHighQuality(
    int pageIndex, {
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 100,
    PageRenderImageType renderImageType = .jpg,
  }) async {
    return await _worker.getImage(
      pageIndex,
      quality: quality,
      targetHeight: targetHeight,
      targetWidth: targetWidth,
      renderImageType: renderImageType,
    );
  }

  @override
  Future<Result<Uint8List, String>> getImageLowQuality(
    int pageIndex, {
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 20,
    PageRenderImageType renderImageType = .jpg,
  }) async {
    return await _worker.getImage(
      pageIndex,
      quality: quality,
      targetHeight: targetHeight,
      targetWidth: targetWidth,
      renderImageType: renderImageType,
    );
  }

  @override
  Future<void> close() async {
    await _worker.close();
  }

  @override
  Future<Result<List<PageSize>, String>> getAllPageSizes() async {
    return await _worker.getAllPageSizes();
  }
}
