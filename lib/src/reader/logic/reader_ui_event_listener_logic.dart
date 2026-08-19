// ignore_for_file: library_private_types_in_public_api

part of '../t_pdf_reader.dart';

mixin ReaderUiEventListenerLogic {
  _TPdfReaderState get state;
  ReaderStateController get stateController;
  AnimationController get animationController;
  void fling(double velocity);

  double _lastScale = 1.0;
  bool useMobileScale = false;

  Widget listenAllUiEvent({
    required Widget Function(BoxConstraints constraints) childBuilder,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onScaleStart: (details) {
        _lastScale = 1.0; // Pinch စတင်ချိန်မှာ 1.0 ပြန်စမယ်
        animationController.stop();
        useMobileScale = false;
        stateController.addEvent(MobileScaleStart());
      },
      onScaleUpdate: (details) {
        // ၁။ Scale (Zoom) လုပ်နေစဉ် - လက် ၂ ချောင်းထောက်ထားချိန်
        if (details.pointerCount > 1) {
          final double currentScale = details.scale;

          // Frame အသစ်နဲ့ အဟောင်းကြား ပြောင်းလဲသွားသည့် Delta Scale ကို တွက်ခြင်း
          final double deltaScale = currentScale / _lastScale;
          _lastScale =
              currentScale; // နောက် Frame အတွက် လက်ရှိ Scale ကို မှတ်ထားမယ်

          final double offsetY = details.focalPointDelta.dy;
          final double offsetX = details.focalPointDelta.dx;

          // Controller သို့ Delta Scale ကိုသာ ပို့ပေးပါမည်
          stateController.setMobileScale(deltaScale, offsetX, offsetY);
          useMobileScale = true;
          return;
        }

        // ၂။ Scroll (Drag) လုပ်နေစဉ် - လက် ၁ ချောင်းတည်း ထောက်ထားချိန်
        final double offsetY = details.focalPointDelta.dy;
        stateController.scrollBy(-offsetY);
      },
      onScaleEnd: (details) {
        stateController.addEvent(MobileScaleEnd());
        if (useMobileScale) {
          stateController.addEvent(MobileScaleChanged());
        }
        // Pinch Zoom မဟုတ်ဘဲ Single Drag အဆုံးမှာပဲ Fling Scroll အလုပ်လုပ်မည်
        final velocity = -details.velocity.pixelsPerSecond.dy;
        if (velocity.abs() > 50) {
          fling(velocity);
        } else {
          // 🟢 Velocity မရှိဘဲ လက်လွှတ်လိုက်ရုံနဲ့ Scroll ရပ်သွားချိန်
          if (!useMobileScale) {
            stateController.addEvent(ScrollEnd());
          }
        }
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerSignal: (event) {
          if (event is PointerScrollEvent) {
            animationController.stop();
            final dy = event.scrollDelta.dy;
            stateController.scrollBy(dy);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final viewportHeight = constraints.maxHeight;
            final viewportWidth = constraints.maxWidth;

            stateController.updateViewportHeight(viewportWidth, viewportHeight);
            stateController.setScrollbarHeight(viewportHeight);

            return childBuilder(constraints);

            // return Stack(
            //   children: [
            //     _body(constraints),
            //     _scrollbar(viewportHeight: viewportHeight),
            //     // testHeaderWidget(),
            //   ],
            // );
          },
        ),
      ),
    );
  }
}
