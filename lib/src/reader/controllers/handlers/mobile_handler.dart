part of '../reader_state_controller.dart';

mixin MobileHandler on IReaderStateController {
  // action
  void setMobileScale(double scale, double offsetX, double offsetY) {
    // 1. Zoom မပြောင်းမီ Old Zoom ဖြင့် Viewport Center (Unscaled Content Y) ကို မှတ်ထားပါ
    final oldZoom = state.zoom;
    final viewportCenterY =
        state.currentOffset + (state.recentViewportHeight / 2);
    final contentPositionY = viewportCenterY / oldZoom;

    // 2. Horizontal Offset (X) ကို တိုက်ရိုက် ပေါင်းစပ်ပါ
    state.currentOffsetX = state.currentOffsetX + offsetX;

    // 3. Zoom Factor တွက်ချက်ခြင်း
    if (scale != 1.0) {
      final double scaleDelta = scale - 1.0;
      final double adjustedScale = 1.0 + (scaleDelta * state.zoomSensitivity);

      // Target Zoom အသစ် တွက်ချက်ခြင်း
      final double targetZoom = (state.zoom * adjustedScale).clamp(
        state.minZoom,
        state.maxZoom,
      );

      if (oldZoom != targetZoom) {
        state.zoom = targetZoom;

        // Page Offsets များကို Zoom အသစ်ဖြင့် ပြန်တွက်ပါ
        pageOffsets = PageOffsetUtils.calculatePageOffsets(
          pages,
          zoom: state.zoom,
        );

        // 4. Zoom ပြောင်းသွားသဖြင့် Old Content Position ကို မူတည်၍ Vertical Offset (Y) ကို ပြန်တွက်ပါ
        // Pinch လုပ်နေစဉ် အပေါ်/အောက် ရွှေ့လိုက်သော offsetY Delta ပါ အချိုးကျ ထည့်တွက်ပေးပါမည်
        final newOffsetY =
            (contentPositionY * state.zoom) -
            (state.recentViewportHeight / 2) -
            offsetY;

        final maxOffsetY = max(0.0, contentHeight - state.recentViewportHeight);
        state.currentOffset = newOffsetY.clamp(0.0, maxOffsetY);

        addEvent(ScaleChanged());
      } else {
        // Zoom မပြောင်းဘဲ (min/max ရောက်နေချိန်) လက်ရွှေ့ရုံသက်သက် ဆိုလျှင် offsetY တိုက်ရိုက် ပေါင်းပါမည်
        final maxOffsetY = max(0.0, contentHeight - state.recentViewportHeight);
        state.currentOffset = (state.currentOffset - offsetY).clamp(
          0.0,
          maxOffsetY,
        );
      }
    } else {
      // Scale မပြောင်းဘဲ Drag ဆွဲရုံသက်သက် အခြေအနေ
      final maxOffsetY = max(0.0, contentHeight - state.recentViewportHeight);
      state.currentOffset = (state.currentOffset - offsetY).clamp(
        0.0,
        maxOffsetY,
      );
    }

    // Horizontal Offset (X) ဘက်အတွက် Bounds ထိန်းချုပ်ပေးခြင်း
    if (pageOffsets.isNotEmpty) {
      final pageWidth = pageOffsets.first.width;
      if (pageWidth <= state.recentViewportWidth) {
        state.currentOffsetX = 0.0; // Screen ထက် သေးပါက Center ၌ ထားမည်
      } else {
        final maxOffsetX = (pageWidth - state.recentViewportWidth) / 2;
        state.currentOffsetX = state.currentOffsetX.clamp(
          -maxOffsetX,
          maxOffsetX,
        );
      }
    }

    updateVisiablePages();
  }
}
