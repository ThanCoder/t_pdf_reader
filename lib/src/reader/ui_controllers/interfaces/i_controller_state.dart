import 'package:t_pdf_reader/src/reader/controllers/types/scrollbar_info.dart';
import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';

/// Represents the current state and configuration of the page reader controller.
abstract class IControllerState {
  /// The number of page images currently visible or retained in the viewport cache.
  int get visiableCachedPagesCount;

  /// The number of pages to preload ahead of the current page.
  int get preloadPageCount;

  /// The rendering quality of high-quality page images, expressed as image height in pixels.
  int get pageImageHeightQuality;

  /// The rendering quality of low-quality page images, expressed as image height in pixels.
  int get pageImageLowQuality;

  /// The rendering strategy used to generate page images.
  PageRenderImageType get renderImageType;

  /// The distance to scroll per scroll step, expressed in logical pixels.
  double get pageScrollStep;

  /// Whether the scrollbar is enabled.
  bool get scrollbarEnable;

  /// The current vertical scroll offset, expressed in logical pixels.
  double get currentOffset;

  /// The total vertical scrollable extent, expressed in logical pixels.
  double get totalOffset;

  /// The height of the visible viewport, expressed in logical pixels.
  double get viewportHeight;

  /// The width of the visible viewport, expressed in logical pixels.
  double get viewportWidth;

  /// Whether the user is currently dragging the scrollbar thumb.
  bool get scrollbarDragging;

  /// The current zoom level.
  double get zoom;

  /// The maximum permitted zoom level.
  double get maxZoom;

  /// The minimum permitted zoom level.
  double get minZoom;

  /// The amount by which the zoom level changes in a single zoom step.
  double get zoomStep;

  /// The total number of pages in the document.
  int get totalPage;

  /// The current page index or page number, depending on the reader's indexing convention.
  int get page;

  /// Information about the current scrollbar position and dimensions, if available.
  ScrollbarInfo? get scrollbarInfo;

  /// The height of the scrollbar thumb, expressed in logical pixels.
  double get scrollbarThumbHeight;

  /// The total height of the scrollbar track, expressed in logical pixels.
  double get scrollbarHeight;

  /// The current horizontal scroll offset, expressed in logical pixels.
  double get currentOffsetX;

  /// Whether the controller has completed initialization and is ready for use.
  bool get isReady;

  /// The current state and usage statistics of the page image cache.
  ImageCacheState get imageCache;
}

/// Represents the current usage and configured limits of the page image cache.
class ImageCacheState {
  /// The maximum number of images that can be stored in the cache.
  final int maxCount;

  /// The maximum memory size allowed for cached images, in bytes.
  final int maxSizeBytes;

  /// The total memory size currently occupied by cached images, in bytes.
  final int size;

  /// The number of images currently stored in the cache.
  final int count;

  /// Creates an immutable snapshot of the image cache state.
  const ImageCacheState({
    required this.maxCount,
    required this.maxSizeBytes,
    required this.size,
    required this.count,
  });
}
