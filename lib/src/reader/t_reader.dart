part of '../t_pdf_reader_base.dart';

class TReader extends StatefulWidget {
  final List<PageSize> pageSizes;
  final PdfBackgroundWorker pdfWorker;
  final TPdfController controller;
  const TReader({
    super.key,
    required this.pageSizes,
    required this.pdfWorker,
    required this.controller,
  });

  @override
  State<TReader> createState() => _TReaderState();
}

class _TReaderState extends State<TReader>
    with
        ScrollbarHandler,
        PageListHandler,
        DesktopHandler,
        MobileHandler,
        SingleTickerProviderStateMixin {
  @override
  final stateController = ReaderStateController();
  @override
  ReaderState get state => stateController.state;

  @override
  TPdfController get tPdfController => widget.controller;

  @override
  PdfBackgroundWorker get pdfWorker => widget.pdfWorker;
  // animate

  @override
  void initState() {
    animateScrollListener(this);
    stateController.setPageSizes(widget.pageSizes, widget.controller);
    super.initState();
    widget.controller._userStream.listen((event) {
      if (event is UserRequestZoomIn) {
        stateController.dispatch(ZoomChanged(state.zoomFactor + 0.1));
      } else if (event is UserRequestZoomOut) {
        stateController.dispatch(ZoomChanged(state.zoomFactor - 0.1));
      } else if (event is UserRequestJumpPage) {
        stateController.dispatch(
          JumpToPage(event.page, event.offsetX, event.zoom),
        );
      }
    });
  }

  @override
  void dispose() {
    animateScrollControllerDispose();
    stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        stateController.dispatch(LayoutChanged(constraints));
        return desktopListener(constraints);
      },
    );
  }

  @override
  Widget listWidget(BoxConstraints constraints) {
    return StreamBuilder(
      stream: stateController.stateStream.distinct(
        (prev, next) => prev.visiblePages == next.visiblePages,
      ),
      builder: (context, snapshot) {
        return Stack(
          children: [...pageListItem(constraints), scrollBar(constraints)],
        );
      },
    );
  }
}
