part of '../reader_state_controller.dart';

mixin LayoutHandler on IReaderStateController {
  void updateViewportHeight(double viewportWidth, double viewportHeight) {
    bool changed = false;

    if (state.recentViewportWidth != viewportWidth) {
      state.recentViewportWidth = viewportWidth;
      addEvent(UpdateViewortWidth());
      changed = true;
    }

    if (state.recentViewportHeight != viewportHeight) {
      state.recentViewportHeight = viewportHeight;
      addEvent(UpdateViewortHeight());
      changed = true;
    }

    if (changed) {
      updateVisiablePages();
    }
  }
}
