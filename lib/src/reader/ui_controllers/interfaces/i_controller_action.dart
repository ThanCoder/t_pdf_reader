abstract class IControllerAction {
  void scrollUp();
  void scrollDown();
  void pageDown();
  void pageUp();

  void scrollbarEnable(bool enable);
  void setFitZoom();
  void jumpPage(int page);
  void setZoom(double value);
  void setScrollbarHeight(double height);

  /// set current offset y
  void setOffset(double offsetY);
  void setOffsetX(double offsetX);

  /// Sensitivity Factor (0.1 = အလွန်နှေး, 0.3 = ငြိမ့်ငြိမ့်လေး, 1.0 = မူလအတိုင်း မြန်)
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
