part of '../reader_state_controller.dart';

mixin ActionsHandler on IReaderStateController {
  void scrollUp() {
    scrollBy(-state.pageScrollStep);
  }

  void scrollDown() {
    scrollBy(state.pageScrollStep);
  }

  void pageDown() {
    scrollBy(state.recentViewportHeight);
  }

  void pageUp() {
    scrollBy(-state.recentViewportHeight);
  }

  void scrollbarEnable(bool enable) {
    state.scrollbarEnable = enable;
    addEvent(ScrollbarUiChanged());
  }

  void jumpPage(int page) => jumpPageIndex(page - 1);
  void jumpPageIndex(int pageIndex) {
    final index = pageOffsets.indexWhere((e) => e.pageIndex == pageIndex);
    if (index == -1) return;
    final p = pageOffsets[index];
    state.currentOffset = p.top;

    addEvent(UserJumpChanged(pageIndex));

    updateVisiablePages();
  }

  void setOffset(double value) {
    final maxOffset = max(0.0, contentHeight - state.recentViewportHeight);
    state.currentOffset = value.clamp(0.0, maxOffset);
    updateVisiablePages();
  }

  void setOffsetX(double value) {
    state.currentOffsetX = value;
    updateVisiablePages();
  }

  void setZoomSensitivity(double zoomSensitivity) {
    state.zoomSensitivity = zoomSensitivity;
  }

  void setMaxZoom(double maxZoom) {
    state.maxZoom = maxZoom;
  }

  void setMinZoom(double minZoom) {
    state.minZoom = minZoom;
  }

  void setPageImageCache({
    int maxCount = 200,
    int maxSizeBytes = 10 * 1024 * 1024,
  }) {
    pageImageCache.setConfig(maxCount, maxSizeBytes);
  }
}
