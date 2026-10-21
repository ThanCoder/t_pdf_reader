import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/cache/page_image_cache.dart';

/// Provides access to streams of events emitted by the page reader controller.
abstract class IControllerStream {
  /// A stream of all reader events emitted by the controller.
  Stream<ReaderEvent> get all;

  /// Emits events when the viewport's position or visible area is updated.
  Stream<UpdateViewort> get updateViewort;

  /// Emits events when the viewport height changes.
  Stream<UpdateViewortHeight> get updateViewortHeight;

  /// Emits events when the viewport width changes.
  Stream<UpdateViewortWidth> get updateViewortWidth;

  /// Emits events when the set of visible or cached pages is updated.
  Stream<UpdateVisibleCachedPages> get updateVisiblePages;

  /// Emits events when the scroll offset changes.
  Stream<UpdateOffset> get updateOffset;

  /// Emits an event when the reader finishes loading the document.
  Stream<ReaderLoaded> get loaded;

  /// Emits an event when the reader's user interface finishes loading.
  Stream<ReaderUILoaded> get uiLoaded;

  /// Emits events when the current page changes.
  Stream<PageChanged> get pageChanged;

  /// Emits events when the zoom level changes.
  Stream<ZoomChanged> get zoomChanged;

  /// Emits events when the scale factor changes.
  Stream<ScaleChanged> get scaleChanged;

  /// Emits events when the scrollbar's UI state changes.
  Stream<ScrollbarUiChanged> get scrollbarUiChanged;

  /// Emits an event when a mobile pinch-to-zoom gesture begins.
  Stream<MobileScaleStart> get mobileScaleStart;

  /// Emits an event when a mobile pinch-to-zoom gesture ends.
  Stream<MobileScaleEnd> get mobileScaleEnd;

  /// Emits an event when scrolling finishes.
  Stream<ScrollEnd> get scrollEnd;

  /// Emits events when the scale factor changes during a mobile scaling gesture.
  Stream<MobileScaleChanged> get mobileScaleChanged;

  /// Emits events related to dragging the scrollbar thumb.
  Stream<ScrollbarDragEvent> get scrollbarDragEvent;

  /// Emits an event when the reader is fully initialized and ready for use.
  Stream<ReaderReady> get ready;

  /// Emits events when the page image rendering strategy changes.
  Stream<PageRenderImageTypeChanged> get pageRenderImageTypeChanged;

  /// Emits events when the page image rendering quality changes.
  Stream<PageRenderImageQualityChanged> get pageRenderImageQualityChanged;

  /// Emits events when the number of pages to preload changes.
  Stream<PreloadPageCountChanged> get preloadPageCountChanged;

  /// Provides access to page image cache events.
  ImageCacheStream get imageCache;
}

/// Provides streams of events describing page image cache operations and changes.
class ImageCacheStream {
  /// A stream of all page image cache events.
  final Stream<PageImageCacheEvent> all;

  /// Emits an event when a page image is added to the cache.
  final Stream<PageImageCachePut> put;

  /// Emits an event when the page image cache is cleared.
  final Stream<PageImageCacheClear> clear;

  /// Emits an event when the cache configuration changes.
  final Stream<PageImageCacheConfigChanged> configChanged;

  /// Emits an event when a page image is removed from the cache.
  final Stream<PageImageCacheRemove> remove;

  /// Creates an immutable collection of page image cache event streams.
  const ImageCacheStream({
    required this.all,
    required this.put,
    required this.clear,
    required this.configChanged,
    required this.remove,
  });
}
