part of '../reader_state_controller.dart';

mixin ZoomHandler on IReaderStateController {
  void setFitZoom() {
    setZoom(fitWidthZoom);
  }

  void setZoom(double value) {
    final targetZoom = value.clamp(state.minZoom, state.maxZoom);

    final oldZoom = state.zoom;

    if (oldZoom == targetZoom) return;

    final viewportCenterY =
        state.currentOffset + state.recentViewportHeight / 2;

    final contentPositionY = viewportCenterY / oldZoom;

    state.zoom = targetZoom;

    pageOffsets = PageOffsetUtils.calculatePageOffsets(pages, zoom: targetZoom);

    final newContentHeight = pageOffsets.isEmpty
        ? 0.0
        : pageOffsets.last.bottom;

    final newOffsetY =
        contentPositionY * targetZoom - state.recentViewportHeight / 2;

    final maxOffsetY = max(0.0, newContentHeight - state.recentViewportHeight);

    state.currentOffset = newOffsetY.clamp(0.0, maxOffsetY);

    // Horizontal
    state.currentOffsetX *= targetZoom / oldZoom;

    if (pageOffsets.isNotEmpty) {
      final pageWidth = pageOffsets.first.width;

      if (pageWidth <= state.recentViewportWidth) {
        state.currentOffsetX = 0.0;
      } else {
        final maxOffsetX = (pageWidth - state.recentViewportWidth) / 2;

        state.currentOffsetX = state.currentOffsetX.clamp(
          -maxOffsetX,
          maxOffsetX,
        );
      }
    }

    addEvent(ZoomChanged(state.zoom));
    updateVisiablePages();

    // print(
    //   'newContentHeight=$newContentHeight '
    //   'viewport=${state.recentViewportHeight} '
    //   'newOffsetY=$newOffsetY '
    //   'maxOffsetY=$maxOffsetY',
    // );
  }

  double get fitWidthZoom {
    if (pages.isEmpty || state.recentViewportWidth <= 0) {
      return 1.0;
    }

    final page = pages.first;

    return state.recentViewportWidth / page.width;
  }

  void zoomIn() {
    setZoom((state.zoom + state.zoomStep).clamp(state.minZoom, state.maxZoom));
  }

  void zoomOut() {
    setZoom((state.zoom - state.zoomStep).clamp(state.minZoom, state.maxZoom));
  }

  void setZoomStep(double step) {
    state.zoomStep = step;
  }
}
