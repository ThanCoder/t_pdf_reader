// ignore_for_file: library_private_types_in_public_api

part of '../t_pdf_reader.dart';

mixin ReaderPdfListLogic {
  _TPdfReaderState get state;
  ReaderStateController get stateController;
  TPdfController get controller;
  IPageImageWorker get worker;

  Widget buildPdfListWidget(BoxConstraints constraints) {
    final placeholderBuilder = controller.widgetBuilder.placeholderBuilder;

    return StreamBuilder(
      stream: stateController.stream.whereType<UpdateVisibleCachedPages>(),
      builder: (context, asyncSnapshot) {
        final list = <Widget>[];
        for (var p in stateController.visibleCachedPages) {
          final top = p.top - stateController.state.currentOffset;
          final defaultCenterLeft = (constraints.maxWidth - p.width) / 2;
          final left = defaultCenterLeft + stateController.state.currentOffsetX;

          list.add(
            Positioned(
              key: ValueKey('item: ${p.pageIndex}'),
              top: top,
              left: left,
              width: p.width,
              height: p.height,
              child: StreamBuilder(
                stream: stateController.stream.where(
                  (e) => e is ScrollbarDragEvent || e is MobileScaleEnd,
                ),
                builder: (context, asyncSnapshot) {
                  if (stateController.state.scrollbarDragging) {
                    final iconSize = min(p.width, p.height) * 0.4;
                    if (placeholderBuilder != null) {
                      return placeholderBuilder(context);
                    }
                    return Icon(
                      Icons.image_not_supported_outlined,
                      size: iconSize,
                    );
                  }
                  if (controller.pageImageWorkerType == .multiThread) {
                    return ReaderMultiThreadItem(
                      offset: p,
                      stateController: stateController,
                      worker: worker,
                      imageCache: stateController.pageImageCache,
                      controller: controller,
                    );
                  }
                  return ReaderSingleThreadItem(
                    offset: p,
                    stateController: stateController,
                    worker: worker,
                    imageCache: stateController.pageImageCache,
                    controller: controller,
                  );
                },
              ),
            ),
          );
        }
        return Stack(children: list);
      },
    );
  }
}
