// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/utils/page_image_cache.dart';

abstract class IControllerStream {
  Stream<ReaderEvent> get all;
  Stream<UpdateViewort> get updateViewort;
  Stream<UpdateViewortHeight> get updateViewortHeight;
  Stream<UpdateViewortWidth> get updateViewortWidth;
  Stream<UpdateVisiblePages> get updateVisiblePages;
  Stream<UpdateOffset> get updateOffset;
  Stream<ReaderLoaded> get loaded;
  Stream<ReaderUILoaded> get uiLoaded;
  Stream<PageChanged> get pageChanged;
  Stream<ZoomChanged> get zoomChanged;
  Stream<ScaleChanged> get scaleChanged;
  Stream<ScrollbarUiChanged> get scrollbarUiChanged;
  Stream<MobileScaleStart> get mobileScaleStart;
  Stream<MobileScaleEnd> get mobileScaleEnd;
  Stream<ScrollEnd> get scrollEnd;
  Stream<MobileScaleChanged> get mobileScaleChanged;
  Stream<ScrollbarDragEvent> get scrollbarDragEvent;
  Stream<ReaderReady> get ready;

  ImageCacheStream get imageCache;
}

class ImageCacheStream {
  final Stream<PageImageCacheEvent> all;
  final Stream<PageImageCachePut> put;
  final Stream<PageImageCacheClear> clear;
  final Stream<PageImageCacheConfigChanged> configChanged;
  final Stream<PageImageCacheRemove> remove;
  const ImageCacheStream({
    required this.all,
    required this.put,
    required this.clear,
    required this.configChanged,
    required this.remove,
  });
}
