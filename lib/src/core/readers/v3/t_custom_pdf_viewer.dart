// ignore_for_file: public_member_api_docs, sort_constructors_first
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

class _PageRange {
  final int index;
  final double start;
  final double end;
  const _PageRange({
    required this.index,
    required this.start,
    required this.end,
  });
}

class _TCustomPdfViewerState extends State<TCustomPdfViewer>
    with SingleTickerProviderStateMixin {
  // ************ Scroll Animation *****************
  late AnimationController _scrollAnimationController;
  final _scrollPhysics = const ClampingScrollPhysics();

  void _animateScroll(double velocity) {
    final simulation = _scrollPhysics.createBallisticSimulation(
      ScrollMetricsNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: _totalHeight,
          pixels: _startScrollY,
          viewportDimension: MediaQuery.of(context).size.height,
          axisDirection: AxisDirection.down,
          devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
        ),
        context: context,
      ).metrics,
      velocity,
    );
    if (simulation == null) return;
    _scrollAnimationController.value = _startScrollY;
    _scrollAnimationController.animateWith(simulation);
  }

  @override
  void initState() {
    super.initState();
    _scrollAnimationController = AnimationController.unbounded(vsync: this);
    _scrollAnimationController.addListener(() {
      double value = _scrollAnimationController.value;

      // အောက်ဆုံး သို့မဟုတ် အပေါ်ဆုံး boundary ရောက်ရင် animation ကို ရပ်လိုက်ခြင်း
      if (value < 0) {
        value = 0;
        _scrollAnimationController.stop();
      } else if (value > _totalHeight) {
        value = _totalHeight;
        _scrollAnimationController.stop();
      }

      setState(() {
        _startScrollY = value;
      });
    });
    _init();
  }

  double _startScrollY = 0.0;
  List<_PageRange> _pageOffsetRanges = [];
  double _totalHeight = 0.0;

  /// ************* Cache Variables *************
  final Map<int, Uint8List?> _loadedPagesCache = {};

  // **************** Render Pdf Image ********************
  Future<TransferableTypedData?> _renderPdfPage(int pageIndex) async {
    return await widget.document.getPageImage(pageIndex);
  }

  void _initPageIntoCache(int index) {
    if (_loadedPagesCache.containsKey(index)) return;

    _loadedPagesCache[index] = null; // Loading ပြဖို့ null အရင်ထားမယ်

    _renderPdfPage(index).then((renderedData) {
      if (!_loadedPagesCache.containsKey(index)) {
        if (renderedData != null) {
          renderedData.materialize();
        }
        return;
      }
      // data ရှိမှ ထည့်မယ်
      if (renderedData != null) {
        final totalSize = _loadedPagesCache.values.fold(
          0,
          (prev, val) => prev + (val == null ? 0 : val.length),
        );
        widget.controller._pdfReaderEventStreamController.add(
          PdfCacheChanged(length: _loadedPagesCache.length, size: totalSize),
        );
        if (!mounted) return;
        setState(() {
          _loadedPagesCache[index] = renderedData.materialize().asUint8List();
        });
      }
    });
  }
  // **************** Render Pdf Image ********************

  // ************ Layout Engine ***********
  double _lastScreenWidth = 0.0;
  double _lastZoom = 1.0;
  static const double _baseCanvasWidth = 390.0;

  void _buildLayout(BoxConstraints constraints) {
    int backupPageIndex = widget.controller._currentPage - 1; // 0-based index
    double relativeOffset = 0.0;

    // လက်ရှိ ရောက်နေတဲ့ Page ရဲ့ အစကနေ လူက ဘယ်လောက်အကွာအဝေးကို ရောက်နေလဲ (Zoom မဝင်ခင် မူရင်းအကွာအဝေးကို ရှာတာပါ)
    if (backupPageIndex >= 0 &&
        backupPageIndex < _pageOffsetRanges.length &&
        _lastZoom != 0.0) {
      double oldPageStart = _pageOffsetRanges[backupPageIndex].start;
      // ရလာတဲ့ ကွာဟချက်ကို _lastZoom နဲ့ စားပြီး "မူရင်း Zoom (1.0) အတိုင်းအတာ" အဖြစ် ပြောင်းမှတ်ထားလိုက်တာပါ
      relativeOffset = (_startScrollY - oldPageStart) / _lastZoom;
    }

    double currentOffset = 0.0;
    _pageOffsetRanges = [];

    for (var page in widget.sizedPages) {
      final ratio = page.width / page.height;
      //canvs အတိုင်းယူမယ်
      final pageHeight = _baseCanvasWidth / ratio;

      final start = currentOffset * currentZoom;
      final end = (currentOffset + pageHeight) * currentZoom;
      // တစ်ခါတည်း သိမ်းလိုက်မယ်
      _pageOffsetRanges.add(
        _PageRange(index: page.index, start: start, end: end),
      );
      //
      currentOffset += pageHeight;
    }
    final originalScreenWidth = constraints.maxWidth;

    //zoom ဝင်ပြီးသား အမြင့်
    _totalHeight = currentOffset * currentZoom;
    if (backupPageIndex >= 0 && backupPageIndex < _pageOffsetRanges.length) {
      // အသစ်ဆောက်လိုက်တဲ့ Layout ထဲက လက်ရှိ Page ရဲ့ Start အသစ်ကို ယူမယ်
      double newPageStart = _pageOffsetRanges[backupPageIndex].start;

      if (_lastZoom != currentZoom) {
        // (က) တကယ်လို့ Zoom ပြောင်းသွားတာဆိုရင် -
        // မူရင်းအကွာအဝေး (relativeOffset) ကို Zoom အသစ်နဲ့ မြှောက်ပြီး Page Start အသစ်ထဲ ပေါင်းထည့်မယ်
        _startScrollY = newPageStart + (relativeOffset * currentZoom);
      } else if (_lastScreenWidth != 0.0 &&
          _lastScreenWidth != originalScreenWidth) {
        // (ခ) တကယ်လို့ Screen လှည့်သွားတာ (Width ပြောင်းသွားတာ) ဆိုရင် -
        // အရင်အတိုင်း Screen အချိုးအစားအတိုင်း ညှိပြီး ပေါင်းထည့်မယ်
        double adjustedRelativeOffset =
            (relativeOffset * _lastZoom / _lastScreenWidth) *
            originalScreenWidth;
        _startScrollY = newPageStart + adjustedRelativeOffset;
      }
    }

    // ၄။ Bound ကျော်မသွားအောင် အမြဲတမ်း ပိတ်ပေးမယ်
    final maxScroll = _totalHeight - constraints.maxHeight;
    _startScrollY = _startScrollY.clamp(0.0, maxScroll > 0 ? maxScroll : 0.0);

    // left-right scroll အတွက်
    final renderWidth = _baseCanvasWidth * currentZoom;

    if (renderWidth > originalScreenWidth) {
      final maxScrollX = (renderWidth - originalScreenWidth) / 2;
      widget.controller._currentReaderOffsetX = widget
          .controller
          ._currentReaderOffsetX
          .clamp(-maxScrollX, maxScrollX);
    } else {
      widget.controller._currentReaderOffsetX = 0.0;
    }

    _lastZoom = currentZoom;
    _lastScreenWidth = originalScreenWidth;
  }
  // ************ Layout Engine ***********

  // ************ Event & Sliding Cache Control ***********
  final Map<int, bool> _visiablePages = {};

  void _updateCurrentPageEvent(double viewportHeight, double screenWidth) {
    if (_pageOffsetRanges.isEmpty) return;

    double viewportTop = _startScrollY;
    double viewportBottom = _startScrollY + viewportHeight;
    double currentViewportCenter = _startScrollY + (viewportHeight / 2);

    int detectedPageIndex = 0;

    for (var page in _pageOffsetRanges) {
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

    for (var page in _pageOffsetRanges) {
      // Buffer Padding အပါအဝင် လက်ရှိ Screen ဧရိယာထဲမှာ ညှပ်နေသလား စစ်ဆေးခြင်း
      bool isVisible =
          (page.start <= viewportBottom + bufferPadding) &&
          (page.end >= viewportTop - bufferPadding);

      if (isVisible) {
        temporaryVisibleMap[page.index] = true;
        _initPageIntoCache(page.index);
      }
    }

    // Current Page ရဲ့ ရှေ့စာမျက်နှာ (တကယ်လို့ Index 0 ထက် ကြီးနေရင်)
    int prevPage = detectedPageIndex - 1;
    if (prevPage >= 0) {
      temporaryVisibleMap[prevPage] = true;
      _initPageIntoCache(prevPage);
    }

    // လက်ရှိ ရောက်နေတဲ့ စာမျက်နှာ (Current Page)
    temporaryVisibleMap[detectedPageIndex] = true;
    _initPageIntoCache(detectedPageIndex);
    // call index

    // Current Page ရဲ့ နောက်စာမျက်နှာ (တကယ်လို့ စုစုပေါင်းစာမျက်နှာအရေအတွက်ထက် ငယ်နေရင်)
    int nextPage = detectedPageIndex + 1;
    if (nextPage < widget.sizedPages.length) {
      temporaryVisibleMap[nextPage] = true;
      _initPageIntoCache(nextPage);
    }

    // visiable page အတွက်
    _visiablePages.clear();
    _visiablePages.addAll(temporaryVisibleMap);
    // send event
    widget.controller._pdfReaderEventStreamController.add(
      PdfVisiablePageChanged(map: _visiablePages),
    );
    // cache ကို limit ထားမယ်
    _maintainCacheLimit(detectedPageIndex);
  }

  // pdf init
  void _init() {
    _initPageIntoCache(0);
    widget.controller._userEvent.listen((event) {
      if (event is UserZoom) {
        _applyZoom(event.zoom);
      }
      if (event is UserJumpToPage) {
        _goToPage(event.page - 1);
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
    _loadedPagesCache.clear();
    _goToPageDelayTimer?.cancel();
    _scrollAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print(_visiablePages);
    // final totalSize = _loadedPagesCache.values.fold(
    //   0,
    //   (prev, val) => prev + (val == null ? 0 : val.length),
    // );
    // print(
    //   'Cache- Length:${_loadedPagesCache.length} - Size: ${totalSize.fileSizeLabel()}',
    // );
    // print('current page: ${widget.controller._currentPage}');

    return LayoutBuilder(
      builder: (context, constraints) {
        _buildLayout(constraints);
        _updateCurrentPageEvent(constraints.maxHeight, constraints.maxWidth);

        return _mobileGestureListener(constraints);
      },
    );
  }

  // ************** Mobile Scroll Pointer Listener ************
  double _baseZoom = 0.0;
  Widget _mobileGestureListener(BoxConstraints constraints) {
    return GestureDetector(
      onScaleStart: (details) {
        _scrollAnimationController.stop();
        _baseZoom = currentZoom;
      },
      onScaleUpdate: (details) {
        // print(details.pointerCount);
        if (details.pointerCount > 1) {
          // လက် ၂ ချောင်း zoom
          _applyZoom(
            (_baseZoom * details.scale).clamp(
              widget.controller.minScale,
              widget.controller.maxScale,
            ),
          );
        } else {
          // mouse,touch -> position ပြောင်းလဲတာ
          final deltaX =
              details.focalPointDelta.dx *
              widget.controller._touchDragSensitivity;
          final deltaY =
              details.focalPointDelta.dy *
              widget.controller._touchDragSensitivity;
          // config ကိုစစ်
          bool offsetXlocked = widget.controller._isOffsetXLocked;
          // Smart lock ပွင့်နေရင်
          if (!widget.controller._isOffsetXAutoLockedEnable) {
            if (currentZoom > 1.0) {
              if (deltaX.abs() > (deltaY.abs() * 1.5)) {
                offsetXlocked = false;
              }
            }
          }
          // update val
          setState(() {
            _startScrollY -= deltaY;
            if (!offsetXlocked) {
              widget.controller._currentReaderOffsetX -= deltaX;
            }
          });
          // ဒါက လက်နဲ့ ဆွဲနေတာ
          // _updateScrollPosition(-deltaY, constraints.maxHeight);

          _buildLayout(constraints);
        }
      },
      onScaleEnd: (details) {
        // - ထည့်ဖို့ အရေးကြီးတယ်နော်
        //touch scroll က ပြောင်းပြန်ကြီး
        final velocity = -details.velocity.pixelsPerSecond.dy;
        if (velocity.abs() > 0) {
          _animateScroll(velocity);
        }
      },
      child: _pointerListener(constraints),
    );
  }

  // ************** Scroll Pointer Listener ************
  Widget _pointerListener(BoxConstraints constraints) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          // print('scroll: ${event.scrollDelta.dy}');
          _updateScrollPosition(
            event.scrollDelta.dy * widget.controller._mouseScrollSensitivity,
            constraints.maxHeight,
          );
        }
      },
      child: _keyboardListener(constraints),
    );
  }

  // ************** Keyboard logic *****************
  final FocusNode _keyboardFocusNode = FocusNode();
  Widget _keyboardListener(BoxConstraints constraints) {
    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // print('key: ${event.logicalKey}');
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _updateScrollPosition(-40.0, constraints.maxHeight);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _updateScrollPosition(40.0, constraints.maxHeight);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _goToPage(widget.controller._currentPage - 1);
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _goToPage(widget.controller._currentPage + 1);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: _buildPageItems(constraints),
    );
  }

  // *************** build page item ********************
  Widget _buildPageItems(BoxConstraints constraints) {
    return Container(
      color: Colors.grey[100],
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: Stack(
        children: [
          // 🚀 Cache ထဲမှာ တကယ်ရှိတဲ့ ၁၁ ရွက်ပဲ Render လုပ်တော့မယ်
          for (int activeIndex in _visiablePages.keys) ...[
            _buildPageItem(activeIndex, constraints.maxWidth),
          ],
          // scrollbar
          if (widget.controller._showScrollbar)
            _scrollBar(constraints.maxHeight),
        ],
      ),
    );
  }

  Widget _buildPageItem(int index, double screenWidth) {
    final page = widget.sizedPages[index];
    final ratio = page.width / (page.height);

    // ၁။ 🎯 Render လုပ်မယ့် Width နဲ့ Height ကို တွက်ခြင်း
    // _buildLayout က တွက်ချက်ပုံစံအတိုင်း ကွက်တိဖြစ်အောင် တွက်ထားပါတယ်
    final renderWidth = _baseCanvasWidth * currentZoom;
    final pageHeight = (_baseCanvasWidth / ratio) * currentZoom;

    final topPosition = _pageOffsetRanges[index].start - _startScrollY;

    // စာရွက်ရဲ့ မူလ အလယ်ဗဟိုနေရာ (ဥပမာ - (400 - 600) / 2 = -100)
    final baseLeft = (screenWidth - renderWidth) / 2;

    // 🔥 -100 ထဲကနေ လက်နဲ့ဆွဲထားတဲ့ _startScrollX ကို နုတ်ပေးခြင်းဖြင့် နေရာမှန်ကို ရောက်သွားပါမယ်
    final leftPosition = baseLeft - widget.controller._currentReaderOffsetX;

    return Positioned(
      left: leftPosition,
      top: topPosition,
      width: renderWidth,
      height: pageHeight,
      child: Column(
        children: [
          Expanded(child: _animatedPageItem(index)),
          _footerPageItem(index, renderWidth),
        ],
      ),
    );
  }

  // ************** Pdf Footer Page Item *******************
  Widget _footerPageItem(int index, double pdfRenderWidth) {
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
  Widget _animatedPageItem(int index) {
    return _pageItem(index);
  }

  // ************** item logic *****************

  Widget _pageItem(int index) {
    final data = _loadedPagesCache[index];
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
  double scrollbarDrapOffset = 0;
  bool _isDragging = false;
  double _currentScrollbarY = 0.0;

  Widget _scrollBar(double screenHeight) {
    double scrollbarHeight = 40;
    double scrollbarWidth = 10;
    double scrollbarRightPosition = 0;
    Widget scrollWidget = _defaultScrollbar;
    if (widget.controller._customScrollbar != null) {
      final customScroll = widget.controller._customScrollbar!(context);
      scrollWidget = customScroll.child;
      scrollbarWidth = customScroll.scrollbarWidth;
      scrollbarHeight = customScroll.scrollbarHeight;
      scrollbarRightPosition = customScroll.scrollbarRightPosition;
    }

    final double maxScroll = _totalHeight - screenHeight;
    final double maxScrollbarTop = screenHeight - scrollbarHeight;

    // ၁။ 🎯 [_isDragging မဟုတ်ခဲရင်] Scrollbar နေရာကို မူရင်းအတိုင်း ပြန်ညှိတဲ့ Math Formula အမှန်
    if (!_isDragging) {
      if (maxScroll > 0) {
        // _totalHeight အစား maxScroll (အမြင့်ဆုံးရွေ့နိုင်တဲ့အမြင့်) နဲ့ အချိုးချရပါမယ်
        _currentScrollbarY = (_startScrollY / maxScroll) * maxScrollbarTop;
      } else {
        _currentScrollbarY = 0.0;
      }
    }

    return Positioned(
      top: _currentScrollbarY,
      right: scrollbarRightPosition,
      width: scrollbarWidth,
      height: scrollbarHeight,
      child: GestureDetector(
        onVerticalDragStart: (details) {
          _isDragging = true;
          scrollbarDrapOffset = details.localPosition.dy;
        },
        onVerticalDragEnd: (details) {
          _isDragging = false;
          setState(() {});
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            // 🎯 ပြင်ဆင်ချက် ၂: Drag Position ကို တွက်တဲ့အခါ globalPosition ထဲကနေ
            // နှိပ်ခဲ့တဲ့ Scrollbar ရဲ့ Offset ကို နှုတ်ပြီး တွက်ရင် ပိုပြီး Smooth ဖြစ်ပြီး မတုန်တော့ပါဘူး
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            double localTop = renderBox
                .globalToLocal(details.globalPosition)
                .dy;

            // လက်ရှိ ရောက်ရမယ့် Scrollbar ရဲ့ Top Position
            _currentScrollbarY = localTop - scrollbarDrapOffset;

            // Boundary ပိတ်မယ်
            _currentScrollbarY = _currentScrollbarY.clamp(0.0, maxScrollbarTop);

            // Scrollbar နေရာကနေ Screen Scroll Position (_startScrollY) ကို ပြန်ပြောင်းလဲတွက်ချက်မယ်
            _startScrollY = (_currentScrollbarY / maxScrollbarTop) * maxScroll;
            _startScrollY = _startScrollY.clamp(0.0, maxScroll);
          });

          // ၄။ 🎯 Scrollbar ဆွဲနေတဲ့အချိန်မှာလည်း လက်ရှိဘယ်နှမျက်နှာ ရောက်နေလဲ ချက်ချင်းသိအောင် လှမ်းခေါ်ပေးရပါမယ်
          _updateCurrentPageEvent(screenHeight, _lastScreenWidth);
        },
        child: scrollWidget,
      ),
    );
  }

  // ************ Scroll Logic ***********
  void _updateScrollPosition(double deltaY, double screenHeight) {
    setState(() {
      // ၁။ Scroll Position ကို အရင်ပေါင်း/နှုတ် လုပ်မယ်
      _startScrollY += deltaY;

      final maxScroll = _totalHeight - screenHeight;

      if (maxScroll > 0) {
        _startScrollY = _startScrollY.clamp(0.0, maxScroll);
      } else {
        _startScrollY = 0.0;
      }
    });

    _updateCurrentPageEvent(screenHeight, _lastScreenWidth);
  }

  // ******************* Zoom ****************
  double get currentZoom => widget.controller.currentZoom;

  // ****************** Maintain Cache ***********************
  void _maintainCacheLimit(int pageIndex) {
    final startKeep = pageIndex - widget.controller.loadCacheLength;
    final endKeep = pageIndex + widget.controller.loadCacheLength;

    final cachesIndex = _loadedPagesCache.keys.toList();

    for (var index in cachesIndex) {
      if (index < startKeep || index > endKeep) {
        if (_loadedPagesCache.containsKey(index)) {
          _loadedPagesCache.remove(index);
        }
      }
    }
  }

  void _applyZoom(double zoomValue) {
    if (widget.controller._currentZoom != zoomValue) {
      widget.controller._currentZoom = zoomValue;
      widget.controller._pdfReaderEventStreamController.add(
        PdfZoomChanged(zoomValue),
      );
    }
    setState(() {});
  }

  // *************** Go To Page Logic *******************
  Timer? _goToPageDelayTimer;
  bool _isPageChanging = false;
  void _goToPage(int pageIndex) async {
    if (_isPageChanging) return;
    if (pageIndex < 0 || pageIndex >= _pageOffsetRanges.length) {
      _isPageChanging = false;
      return;
    }
    if (!mounted) return;

    setState(() {
      _isPageChanging = true;
      _startScrollY = _pageOffsetRanges[pageIndex].start;
    });
    widget.controller._pdfReaderEventStreamController.add(
      PdfPageChanged(pageIndex + 1),
    );

    _goToPageDelayTimer = Timer(Duration(milliseconds: 300), () {
      _isPageChanging = false;
    });
  }
}
