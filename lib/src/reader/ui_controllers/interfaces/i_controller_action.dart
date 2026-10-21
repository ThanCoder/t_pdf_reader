import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';

/// Defines the actions available for controlling the page reader.
abstract class IControllerAction {
  /// Sets the number of pages to preload ahead of the current page.
  void setPreloadPageCount(int preloadPageCount);

  /// Sets the target image height in pixels for high-quality page rendering.
  void setPageImageHeightQuality(int pageImageHeightQuality);

  /// Sets the target image height in pixels for low-quality page rendering.
  void setPageImageLowQuality(int pageImageLowQuality);

  /// Sets the page image rendering strategy.
  void setRenderImageType(PageRenderImageType type);

  /// Scrolls the document upward.
  void scrollUp();

  /// Scrolls the document downward.
  void scrollDown();

  /// Moves the viewport down by one page.
  void pageDown();

  /// Moves the viewport up by one page.
  void pageUp();

  /// Enables or disables the scrollbar.
  void scrollbarEnable(bool enable);

  /// Adjusts the zoom level to fit the document within the viewport.
  void setFitZoom();

  /// Jumps to the specified page.
  ///
  /// The page numbering convention depends on the controller implementation.
  void jumpPage(int page);

  /// Sets the zoom level.
  void setZoom(double value);

  /// Sets the height of the scrollbar track in logical pixels.
  void setScrollbarHeight(double height);

  /// Sets the vertical scroll offset in logical pixels.
  void setOffset(double offsetY);

  /// Sets the horizontal scroll offset in logical pixels.
  void setOffsetX(double offsetX);

  /// Sets the zoom sensitivity factor.
  ///
  /// Lower values produce slower zoom changes, while higher values produce
  /// faster zoom changes.
  ///
  /// Example:
  /// - `0.1`: Very slow zooming.
  /// - `0.3`: Smooth, gradual zooming.
  /// - `1.0`: Default sensitivity.
  void setZoomSensitivity(double zoomSensitivity);

  /// Sets the maximum permitted zoom level.
  void setMaxZoom(double maxZoom);

  /// Sets the minimum permitted zoom level.
  void setMinZoom(double minZoom);

  /// Increases the current zoom level by one zoom step.
  void zoomIn();

  /// Decreases the current zoom level by one zoom step.
  void zoomOut();

  /// Sets the amount by which the zoom level changes per zoom step.
  void setZoomStep(double step);

  /// Configures the page image cache limits.
  ///
  /// Defaults:
  /// - Maximum image count: `200`.
  /// - Maximum memory usage: `10 MB` (`10 * 1024 * 1024` bytes).
  ///
  /// The cache is constrained by both the maximum image count and the
  /// maximum memory size.
  void setPageImageCache({
    int maxCount = 200,
    int maxSizeBytes = 10 * 1024 * 1024,
  });

  /// Removes all cached page images.
  void clearImageCache();
}
