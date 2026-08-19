// ignore_for_file: library_private_types_in_public_api

part of '../t_pdf_reader.dart';

mixin ReaderPdfListLogic {
  _TPdfReaderState get state;
  ReaderStateController get stateController;
  TPdfController get controller;
  PdfReaderWorker get worker;

  Widget buildPdfListWidget(BoxConstraints constraints) {
    return StreamBuilder(
      stream: stateController.stream.whereType<UpdateVisiblePages>(),
      builder: (context, asyncSnapshot) {
        // print(
        //   'visible: ${stateController.visiblePages.map((e) => e.pageIndex).toList()}',
        // );
        // print('visiable len: ${stateController.visiblePages.length}');
        // print('Cache Count: ${stateController.imageCache.len}');
        // print('Cache Size: ${stateController.imageCache.size.toFileSizeLabel()}');
        // print('offset page: ${stateController.visiblePages.first}');
        final list = <Widget>[];
        for (var p in stateController.visiblePages) {
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
                    return Icon(
                      Icons.image_not_supported_outlined,
                      size: iconSize,
                    );
                  }
                  return ReaderItem(
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
