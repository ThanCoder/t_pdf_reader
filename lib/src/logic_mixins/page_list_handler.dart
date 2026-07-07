import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/reader/page_list_item.dart';
import 'package:t_pdf_reader/src/state/reader_state.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';
import 'package:than_pdf_engine/core/pdf_background_worker.dart';

mixin PageListHandler {
  BuildContext get context;
  ReaderState get state;
  ReaderStateController get stateController;
  PdfBackgroundWorker get pdfWorker;
  TPdfController get tPdfController;

  List<Widget> pageListItem(BoxConstraints constraints) {
    final list = <Widget>[];
    // print(state.visiblePages);
    // print('pages: ${state.visiblePages.map((e) => e.pageIndex).join(',')}');
    for (var page in state.visiblePages) {
      final topPos = page.startOffset - state.currentScrollOffset;

      ///offset x
      double leftPos =
          ((constraints.maxWidth - page.width) / 2) -
          state.currentScrollOffsetX;
      list.add(
        Positioned(
          key: ValueKey('page_index_${page.pageIndex}'),
          top: topPos,
          left: leftPos,
          width: page.width,
          height: page.height,
          child: PageListItem(
            page: page,
            pdfWorker: pdfWorker,
            controller: tPdfController,
          ),
        ),
      );
    }
    return list;
  }
}
