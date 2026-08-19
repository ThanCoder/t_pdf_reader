abstract class IControllerAction {
  void setFitZoom();
  void jumpPage(int page);
  void setZoom(double value);
  void setScrollbarHeight(double height);

  /// set current offset y
  void setOffset(double offsetY);
  void setOffsetX(double offsetX);

  void setZoomSensitivity(double zoomSensitivity);

  void setMaxZoom(double maxZoom);

  void setMinZoom(double minZoom);
  void zoomIn();
  void zoomOut();
  void setZoomStep(double step);

  /// Default: 10 MB
  ///
  /// Count: 200
  void setPageImageCache({
    int maxCount = 200,
    int maxSizeBytes = 10 * 1024 * 1024,
  });
}
