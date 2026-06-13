part of 't_pdf_render_v3_base.dart';

class TCustomPdfViewer extends StatefulWidget {
  final List<PdfSizedPage> sizedPages;
  final TPdfControllerV3 controller;
  final PdfBackgroundDocument document;
  const TCustomPdfViewer({
    super.key,
    required this.sizedPages,
    required this.controller,
    required this.document,
  });

  @override
  State<TCustomPdfViewer> createState() => _TCustomPdfViewerState();
}

class _TCustomPdfViewerState extends State<TCustomPdfViewer>
    with
        SingleTickerProviderStateMixin,
        ViewerLayoutMixin,
        ViewerCacheMixin,
        ViewerScrollAnimationMixin,
        TouchZoomHandlerMixin,
        ScrollKeyboardHandlerMixin,
        ViewerPageBuildHandler,
        ScrollbarHandler {
  @override
  void initState() {
    super.initState();
    // ************ Scroll Animation *****************
    initViewerAnimation();
    _init();
  }

  // ************ Layout Engine ***********
  @override
  List<PageRange> pageOffsetRanges = [];

  @override
  double startScrollY = 0.0;

  @override
  double totalHeight = 0.0;

  @override
  double get currentZoom => widget.controller.currentZoom;

  // ******************************************************

  // ************ Event & Sliding Cache Control ***********
  final Map<int, bool> _visiablePages = {};

  void _updateCurrentPageEvent(double viewportHeight, double screenWidth) {
    if (pageOffsetRanges.isEmpty) return;

    double viewportTop = startScrollY;
    double viewportBottom = startScrollY + viewportHeight;
    double currentViewportCenter = startScrollY + (viewportHeight / 2);

    int detectedPageIndex = 0;

    for (var page in pageOffsetRanges) {
      // Screen ရဲ့ အလယ်ဗဟိုဟာ ဒီစာမျက်နှာရဲ့ အစနဲ့ အဆုံးကြားထဲမှာ ရှိနေသလား?
      if (currentViewportCenter >= page.start &&
          currentViewportCenter < page.end) {
        detectedPageIndex = page.index;
        break;
      }
    }

    // send controller to update
    Future.microtask(() {
      if (!mounted) return;
      widget.controller._currentPage = detectedPageIndex + 1;
      widget.controller._pdfReaderEventStreamController.add(
        PdfPageChanged(detectedPageIndex + 1),
      );
    });
    if (_isDragging) return;
    Map<int, bool> temporaryVisibleMap = {};
    final double bufferPadding = 100.0;

    for (var page in pageOffsetRanges) {
      // Buffer Padding အပါအဝင် လက်ရှိ Screen ဧရိယာထဲမှာ ညှပ်နေသလား စစ်ဆေးခြင်း
      bool isVisible =
          (page.start <= viewportBottom + bufferPadding) &&
          (page.end >= viewportTop - bufferPadding);

      if (isVisible) {
        temporaryVisibleMap[page.index] = true;
        initPageIntoCache(page.index);
      }
    }

    // Current Page ရဲ့ ရှေ့စာမျက်နှာ (တကယ်လို့ Index 0 ထက် ကြီးနေရင်)
    int prevPage = detectedPageIndex - 1;
    if (prevPage >= 0) {
      temporaryVisibleMap[prevPage] = true;
      initPageIntoCache(prevPage);
    }

    // လက်ရှိ ရောက်နေတဲ့ စာမျက်နှာ (Current Page)
    temporaryVisibleMap[detectedPageIndex] = true;
    initPageIntoCache(detectedPageIndex);
    // call index

    // Current Page ရဲ့ နောက်စာမျက်နှာ (တကယ်လို့ စုစုပေါင်းစာမျက်နှာအရေအတွက်ထက် ငယ်နေရင်)
    int nextPage = detectedPageIndex + 1;
    if (nextPage < widget.sizedPages.length) {
      temporaryVisibleMap[nextPage] = true;
      initPageIntoCache(nextPage);
    }

    // visiable page အတွက်
    _visiablePages.clear();
    _visiablePages.addAll(temporaryVisibleMap);
    // send event
    widget.controller._pdfReaderEventStreamController.add(
      PdfVisiablePageChanged(map: _visiablePages),
    );
    // cache ကို limit ထားမယ်
    maintainCacheLimit(detectedPageIndex);
  }

  // pdf init or event
  void _init() async {
    await initPageIntoCache(0);

    widget.controller._userEvent.listen((event) {
      if (event is UserZoom) {
        _applyZoom(event.zoom);
      }
      if (event is UserJumpToPage) {
        _goToPage(event.page - 1);
      }
      if (event is UserSetOffsetX) {
        _applyZoom(event.zoom, offsetX: event.offsetX);
        widget.controller._notifyListeners();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller._stopWatch.stop();
      widget.controller._pdfReaderEventStreamController.add(
        PdfOnLoaded(
          page: 1,
          totalPage: widget.controller._totalPages,
          loadedElapsedTime: widget.controller._stopWatch.elapsed,
        ),
      );
    });
  }

  // dispose
  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    loadedPagesCache.clear();
    _goToPageDelayTimer?.cancel();
    _scrollAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print('offset x: ${widget.controller._currentReaderOffsetX}');
    // print('old - offsetX: $_oldOffsetX');
    // print('layout width: $_layoutBuilderMaxWidth');
    // print(_visiablePages);
    // final totalSize = loadedPagesCache.values.fold(
    //   0,
    //   (prev, val) => prev + (val == null ? 0 : val.length),
    // );
    // print(
    //   'Cache- Length:${loadedPagesCache.length} - Size: ${totalSize.fileSizeLabel()}',
    // );
    // print('current page: ${widget.controller._currentPage}');

    return LayoutBuilder(
      builder: (context, constraints) {
        buildLayout(constraints);
        _updateCurrentPageEvent(constraints.maxHeight, constraints.maxWidth);

        return mobileGestureListener(constraints);
      },
    );
  }

  // ************** Mobile Scroll Pointer Listener ************
  @override
  void applyZoom(double zoom) {
    _applyZoom(zoom);
  }

  @override
  void animateScroll(double velocity) {
    viewerAnimateScroll(velocity);
  }

  @override
  void scrollAnimationControllerStop() {
    viewerAnimateScrollStop();
  }

  // ************** Scroll Pointer && Keyboard Handler ************

  @override
  void goToPage(int pageIndex) {
    _goToPage(pageIndex);
  }

  // *************** build page item ********************
  @override
  Map<int, bool> get visiablePages => _visiablePages;

  // ************** Pdf Footer Page Item *******************
  @override
  Widget footerPageItem(int index, double pdfRenderWidth) {
    if (widget.controller._customPdfPageFooterWidget == null) {
      return SizedBox.shrink();
    }
    final custom = widget.controller._customPdfPageFooterWidget!(
      context,
      index + 1,
    );
    final double currentScale = currentZoom < 1 ? currentZoom : 1;
    double baseFooterHeight = custom.basefooterHeight;
    Widget customWidget = custom.child;

    return SizedBox(
      width: pdfRenderWidth,
      height: baseFooterHeight * currentScale,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Transform.scale(
            scale: currentScale,
            alignment: Alignment.center,
            child: SizedBox(
              width: pdfRenderWidth / currentScale,
              height: baseFooterHeight,
              child: customWidget,
            ),
          );
        },
      ),
    );
    // return SizedBox(
    //   width: pdfRenderWidth,
    //   // Zoom သေးရင် အမြင့်ပဲ ကျုံ့မယ်
    //   height: 40 * (currentZoom < 1 ? currentZoom : 1),
    //   child: Container(
    //     decoration: const BoxDecoration(color: Colors.blueGrey),
    //     child: FittedBox(
    //       // 🎯 အမြင့်ဘောင်ထဲဝင်အောင်ပဲ စာသားကို လိုက်သေးခိုင်းတာ၊ Width ကို မထိဘူး
    //       fit: BoxFit.fitHeight,
    //       child: Padding(
    //         // Padding ကအစ အချိုးကျ သေးသွားမယ်
    //         padding: const EdgeInsets.symmetric(vertical: 4.0),
    //         child: Text(
    //           'Page: ${index + 1}',
    //           style: const TextStyle(color: Colors.white),
    //         ),
    //       ),
    //     ),
    //   ),
    // );
  }

  // Animate Page Item
  @override
  Widget animatedPageItem(int index) {
    return _pageItem(index);
  }

  // ************** item logic *****************

  Widget _pageItem(int index) {
    final data = loadedPagesCache[index];
    if (data != null) {
      return RepaintBoundary(
        child: Image.memory(
          data,
          fit: BoxFit.fill,
          width: double.infinity, // အပြည့်ယူခိုင်းပါ
          height: double.infinity,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        // border: Border.all(color: Colors.red, width: 2),
      ),
      child: Center(child: const CircularProgressIndicator.adaptive()),
    );
  }

  // ************ Scrollbar Logic ***********
  @override
  double get lastScreenWidth => _lastScreenWidth;

  // ************ Scroll Logic ***********
  @override
  void updateScrollPosition(double deltaY, double screenHeight) {
    setState(() {
      // ၁။ Scroll Position ကို အရင်ပေါင်း/နှုတ် လုပ်မယ်
      startScrollY += deltaY;

      final maxScroll = totalHeight - screenHeight;

      if (maxScroll > 0) {
        startScrollY = startScrollY.clamp(0.0, maxScroll);
      } else {
        startScrollY = 0.0;
      }
    });

    updateCurrentPageEvent(screenHeight, _lastScreenWidth);
  }

  // ******************* Zoom ****************

  void _applyZoom(double zoomValue, {double? offsetX}) {
    if (widget.controller._currentZoom != zoomValue) {
      widget.controller._currentZoom = zoomValue;
      widget.controller._pdfReaderEventStreamController.add(
        PdfZoomChanged(zoomValue),
      );
    }
    if (offsetX != null) {
      widget.controller._currentReaderOffsetX = offsetX;
    }
    setState(() {});
  }

  // *************** Go To Page Logic *******************
  Timer? _goToPageDelayTimer;
  bool _isPageChanging = false;
  void _goToPage(int pageIndex) async {
    if (_isPageChanging) return;
    if (pageIndex < 0 || pageIndex >= pageOffsetRanges.length) {
      _isPageChanging = false;
      return;
    }
    if (!mounted) return;

    setState(() {
      _isPageChanging = true;
      startScrollY = pageOffsetRanges[pageIndex].start;
    });
    widget.controller._pdfReaderEventStreamController.add(
      PdfPageChanged(pageIndex + 1),
    );

    _goToPageDelayTimer = Timer(Duration(milliseconds: 300), () {
      _isPageChanging = false;
    });
  }

  @override
  void updateCurrentPageEvent(double screenHeight, double lastScreenWidth) {
    _updateCurrentPageEvent(screenHeight, lastScreenWidth);
  }
}
