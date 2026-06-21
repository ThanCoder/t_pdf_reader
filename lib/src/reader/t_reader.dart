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

class _TReaderState extends State<TReader> {
  final stateController = ReaderStateController();
  ReaderState get state => stateController.state;

  @override
  void initState() {
    stateController.setPageSizes(widget.pageSizes);
    super.initState();
  }

  @override
  void dispose() {
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

  Widget desktopListener(BoxConstraints constraints) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          stateController.dispatch(MouseScrollChanged(event.scrollDelta));
        }
      },
      child: _listWidget(constraints),
    );
  }

  Widget _listWidget(BoxConstraints constraints) {
    return StreamBuilder(
      stream: stateController.stateStream.distinct(
        (prev, next) => prev.visiblePages == next.visiblePages,
      ),
      builder: (context, snapshot) {
        return Stack(
          children: [..._listItem(constraints), scrollBar(constraints)],
        );
      },
    );
  }

  Widget scrollBar(BoxConstraints constraints) {
    final double thumbWidth = 50;
    final double thumbHeight = 50;
    final maxScroll = (state.totalContentHeight - constraints.maxHeight).clamp(
      0.1,
      double.infinity,
    );
    final maxTrackHeight = constraints.maxHeight - thumbHeight;

    double topPos = (state.currentScrollOffset / maxScroll) * maxTrackHeight;
    return Positioned(
      top: topPos,
      right: 5,
      width: thumbWidth,
      height: thumbHeight,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          // ၁။ စခရင်တစ်ခုလုံးမှာရှိတဲ့ GestureDetector ရဲ့ RenderBox ကို ရှာတယ်
          final RenderBox renderBox = context.findRenderObject() as RenderBox;

          // ၂။ အပေါ်က Stack သို့မဟုတ် တစ်ပြင်လုံးရဲ့ နောက်ခံ (Parent) ရဲ့ Top-Left ကို ရှာရန်
          // globalPosition ကနေ တည်ငြိမ်တဲ့ local position တစ်ခုပြောင်းယူခြင်း ဖြစ်ပါတယ်
          final parentLocalPosition = renderBox.globalToLocal(
            details.globalPosition,
          );

          // ၃။ parentLocalPosition.dy က Thumb နေရာရွေ့ပေမယ့် လိုက်မပြောင်းတော့ဘဲ ငြိမ်နေမှာပါ
          double newOffset = parentLocalPosition.dy - (thumbHeight / 2);
          newOffset = newOffset.clamp(0.0, maxTrackHeight);

          // ၄။ Scroll Offset အသစ် ပြန်တွက်ခြင်း
          double newScrollOffset = (newOffset / maxTrackHeight) * maxScroll;

          // print(
          //   'totalContentHeight: ${state.totalContentHeight} - newOffset: $newScrollOffset',
          // );
          stateController.dispatch(MouseThumbScrollChanged(newScrollOffset));
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.grabbing,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _listItem(BoxConstraints constraints) {
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
          child: Container(
            width: page.width,
            height: page.height,
            color: Colors.blueGrey,
            child: Center(child: Text('Page: ${page.pageIndex}')),
          ),
        ),
      );
    }
    return list;
  }
}
