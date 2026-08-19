part of '../reader_state_controller.dart';

mixin ScrollbarHandler on IReaderStateController {
  void scrollByScrollbar(double dy) {
    final info = state.scrollbarInfo;
    if (info == null) return;

    final maxOffset = contentHeight - state.recentViewportHeight;
    final maxThumbOffset =
        state.scrollbarHeight -
        info.thumbHeight; // Dynamic Thumb Height ကို သုံးရပါမည်

    if (maxThumbOffset <= 0) return;

    final delta = (dy / maxThumbOffset) * maxOffset;
    scrollBy(delta);
  }

  void setScrollbarHeight(double height) {
    state.scrollbarHeight = height;
    addEvent(ScrollbarUiChanged());
  }

  ScrollbarInfo? getScrollbarInfo() {
    if (contentHeight <= state.recentViewportHeight ||
        state.scrollbarHeight <= 0) {
      return null;
    }

    final maxOffset = contentHeight - state.recentViewportHeight;
    if (maxOffset <= 0) return null;

    final thumbHeight = max(
      state.scrollbarThumbHeight,
      state.scrollbarHeight * state.recentViewportHeight / contentHeight,
    );

    final maxThumbOffset = state.scrollbarHeight - thumbHeight;

    // thumbTop မကျော်သွားစေရန် clamp ခတ်ပေးပါ
    final thumbTop = ((state.currentOffset / maxOffset) * maxThumbOffset).clamp(
      0.0,
      maxThumbOffset,
    );

    return ScrollbarInfo(thumbTop: thumbTop, thumbHeight: thumbHeight);
  }
}
