import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class ReaderScrollbar extends StatelessWidget {
  const ReaderScrollbar({
    super.key,
    required this.stateController,
    required this.animationController,
    required this.tController,
  });

  final ReaderStateController stateController;
  final TPdfController tController;
  final AnimationController animationController;

  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: stateController.stream.whereType<ScrollbarUiChanged>(),
      builder: (context, snapshot) {
        if (!stateController.state.scrollbarEnable) {
          return Positioned(child: SizedBox.shrink());
        }
        final info = stateController.state.scrollbarInfo;
        if (info == null) {
          return Positioned(child: SizedBox.shrink());
        }
        //build in
        double? posRight = 5;
        double? posLeft;
        double thumbWidth = 15;
        double thumbHeight = info.thumbHeight;

        Widget? customBuilder;
        //*****************Scrollbar Custom Builder********************************* */
        final scrollbarBuilder = tController.widgetBuilder.scrollbarBuilder;
        if (scrollbarBuilder != null) {
          final func = scrollbarBuilder(context, stateController.state.page);
          customBuilder = func.builder;
          final info = func.widgetInfo;
          if (info.positionLeft != null) {
            posLeft = info.positionLeft;
            posRight = null;
          } else if (info.positionRight != null) {
            posRight = info.positionRight;
            posLeft = null;
          }
          thumbHeight = info.thumbHeight;
          thumbWidth = info.thumbWidth;
        }
        //*****************Scrollbar Custom Builder********************************* */

        return Positioned(
          top: info.thumbTop,
          left: posLeft,
          right: posRight,
          width: thumbWidth,
          height: thumbHeight,
          child: GestureDetector(
            onVerticalDragStart: (_) {
              stateController.state.scrollbarDragging = true;
              stateController.addEvent(ScrollbarDragEvent(true));
              animationController.stop();
            },
            onVerticalDragEnd: (details) {
              stateController.state.scrollbarDragging = false;
              stateController.addEvent(ScrollbarDragEvent(false));
            },
            onVerticalDragUpdate: (details) {
              final info = stateController.state.scrollbarInfo;
              if (info == null) return;

              final contentHeight = stateController.contentHeight;
              final viewportHeight = stateController.state.recentViewportHeight;
              final scrollbarHeight = stateController
                  .state
                  .scrollbarHeight; // သို့မဟုတ် viewportHeight

              // Max offsets
              final maxOffset = contentHeight - viewportHeight;

              // 🟢 CORRECT: info.thumbHeight ကို တိုက်ရိုက်သုံးရပါမည်
              final maxThumbOffset = scrollbarHeight - info.thumbHeight;

              if (maxThumbOffset <= 0) return;

              // Real Drag Delta Ratio
              final delta = (details.delta.dy / maxThumbOffset) * maxOffset;

              stateController.scrollBy(delta);
            },
            child:
                customBuilder ??
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: col.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      .new(
                        color: col.onPrimaryContainer.withValues(alpha: .45),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
          ),
        );
      },
    );
  }
}
