part of 'i_page_image_worker.dart';

class PageImageWorkerMultiThread extends IPageImageWorker {
  final _worker = PdfReaderWorker();
  // for hight quality
  final _worker2 = PdfReaderWorker();

  new(super.type);

  @override
  Future<Result<bool, PdfReaderWorkerOpenErrorResult>> open(String path) async {
    // final res = await Future.wait([_worker.open(path), _worker2.open(path)]);
    // return res.first;
    final res = await _worker.open(path);
    if (res.isErr) {
      return res;
    }
    await _worker2.open(path);
    return res;
  }

  @override
  Future<Result<Uint8List, String>> getImageHighQuality(
    int pageIndex, {
    int targetWidth = 0,
    int targetHeight = 0,
    int quality = 100,
    PageRenderImageType renderImageType = .jpg,
  }) async {
    // print('getImageHighQuality: $pageIndex');
    return await _worker2.getImage(
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
    // print('getImageLowQuality: $pageIndex');

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
    await _worker2.close();
  }

  @override
  Future<Result<List<PageSize>, String>> getAllPageSizes() async {
    return await _worker.getAllPageSizes();
  }
}
