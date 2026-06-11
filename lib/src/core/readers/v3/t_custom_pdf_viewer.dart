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

class _TCustomPdfViewerState extends State<TCustomPdfViewer> {
  double _startScrollY = 0.0;
  List<double> _pageOffsets = [];
  double _totalHeight = 0.0;
  double _spacing = 12;
  double _paddingWidth = 40;

  /// ************* Cache Variables *************
  int _currentPageIndex = 0;
  final int _bufferSize = 10;
  final Map<int, Uint8List?> _loadedPagesCache = {};

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
      if (renderedData == null) {
        return;
      }

      if (!mounted) return;
      setState(() {
        _loadedPagesCache[index] = renderedData.materialize().asUint8List();
        print("✅ [CACHE] Page $index Render ပြီးလို့ ဒေတာအစစ် သွင်းလိုက်ပြီ။");
      });
    });
  }

  /// ************ Layout Engine ***********
  double _lastScreenWidth = 0.0;

  void _buildLayout(double originalScreenWidth) {
    // 🚀 ၁။ Screen အမှန်တကယ် ပြောင်း/မပြောင်း စစ်ဖို့ မူရင်းအကျယ်ကိုပဲ သုံးပြီး Ratio ကြိုမှတ်မယ်
    double scrollRatio = _totalHeight > 0
        ? (_startScrollY / _totalHeight)
        : 0.0;

    // 🚀 ၂။ မူရင်း variable ကို သွားမဖျက်ဘဲ ဒေသန္တရ (Local) variable အသစ်တစ်ခုနဲ့ပဲ Padding ကို နှုတ်မယ်
    final usableWidth = originalScreenWidth - _paddingWidth;

    double currentOffset = 0.0;
    _pageOffsets = [];

    for (var page in widget.sizedPages) {
      _pageOffsets.add(currentOffset);
      final ratio = page.width / page.height;
      final pageHeight =
          usableWidth / ratio; // 🚀 usableWidth နဲ့ပဲ အမြင့်တွက်မယ်
      currentOffset += pageHeight + _spacing;
    }
    _totalHeight = currentOffset;

    if (_lastScreenWidth != 0.0 && _lastScreenWidth != originalScreenWidth) {
      _startScrollY = scrollRatio * _totalHeight;
    }

    _lastScreenWidth = originalScreenWidth; // မူရင်း Size အစစ်ကိုပဲ သိမ်းထားမယ်
  }

  // 🚀 ၁။ Scroll Position တွက်ချက်မှုကို ရိုးရိုးရှင်းရှင်းပဲ ထားပါမယ် (Zoom မမြှောက်/မစားပါနဲ့)
  void _updateScrollPosition(double deltaY, double screenHeight) {
    setState(() {
      _startScrollY += deltaY;
      double maxScroll = _totalHeight - screenHeight;
      if (maxScroll < 0) maxScroll = 0.0;
      _startScrollY = _startScrollY.clamp(0.0, maxScroll);
    });
  }

  // 🚀 ၃။ Viewport မှာ စာရွက်တွေ နေရာချတဲ့သင်္ချာ (ဒီနေရာမှာ Zoom ကို အကျိုးရှိရှိ သုံးပါမယ်)
  Widget _buildPageItem(int index, double screenWidth) {
    final double zoom = widget.controller.currentZoom;

    final usableWidth = (screenWidth - _paddingWidth);
    final page = widget.sizedPages[index];
    final ratio = page.width / page.height;

    final pageHeight = (usableWidth / ratio) * zoom;
    final renderWidth = usableWidth * zoom;

    // 🎯 _startScrollY ကော Offset ကောကို Zoom ချဲ့ထားတဲ့ အချိုးအတိုင်း နေရာချပေးခြင်း
    final topPosition = (_pageOffsets[index] * zoom) - (_startScrollY * zoom);
    final leftPosition = (screenWidth - renderWidth) / 2;

    return Positioned(
      left: leftPosition,
      top: topPosition,
      width: renderWidth,
      height: pageHeight,
      child: _pageItem(index),
    );
  }

  // 🚀 ၄။ Scrollbar Logic ကိုလည်း ဒိုင်နမစ် အချိုးကျအောင် ညှိပါမယ်
  Widget _scrollBar(double screenHeight) {
    const double scrollbarHeight = 40;

    if (!_isDragging) {
      _currentScrollbarY = (_startScrollY / _totalHeight) * screenHeight;
      if (_currentScrollbarY + scrollbarHeight > screenHeight) {
        _currentScrollbarY = screenHeight - scrollbarHeight;
      }
    }
    return Positioned(
      top: _currentScrollbarY,
      right: 5,
      width: 10,
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
            _currentScrollbarY += details.delta.dy;
            if (_currentScrollbarY < 0) _currentScrollbarY = 0;
            double maxScrollbarTop = screenHeight - scrollbarHeight;
            if (_currentScrollbarY > maxScrollbarTop) {
              _currentScrollbarY = maxScrollbarTop;
            }

            double maxScroll = _totalHeight - screenHeight;
            if (maxScroll > 0) {
              // 🎯 ဒိုင်နမစ်တန်ဖိုးဖြစ်အောင် ပြောင်းလဲလိုက်ခြင်း
              _startScrollY =
                  (_currentScrollbarY / maxScrollbarTop) * maxScroll;
            } else {
              maxScroll = 0.0;
            }

            _startScrollY = _startScrollY.clamp(0.0, maxScroll);
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  /// ************ Event & Sliding Cache Control ***********
  // 🚀 ၂။ Current Page ရှာတဲ့နေရာမှာ အောက်က Loop ကို Zoom နဲ့ ကိုက်ညီအောင် ပြင်ပါမယ်
  void _updateCurrentPageEvent(double viewportHeight, double screenWidth) {
    if (_pageOffsets.isEmpty) return;
    if (_isDragging) return;

    double currentViewportCenter = _startScrollY + (viewportHeight / 2);
    int detectedPageIndex = 0;

    for (var i = 0; i < _pageOffsets.length; i++) {
      final pageStart = _pageOffsets[i];
      final ratio = widget.sizedPages[i].width / widget.sizedPages[i].height;
      final pageHeight = (screenWidth - _paddingWidth) / ratio;
      final pageEnd = pageStart + pageHeight;

      // 💡 _startScrollY ရော Offset ရောက Standard ချင်း တူနေလို့ Zoom ထည့်မြှောက်စရာ မလိုတော့ဘဲ ကွက်တိ မှန်သွားပါပြီ
      if (currentViewportCenter >= pageStart &&
          currentViewportCenter <= pageEnd) {
        detectedPageIndex = i;
        break;
      }
    }

    Future.microtask(() {
      if (!mounted) return;
      widget.controller._currentPage = detectedPageIndex + 1;
      widget.controller._pdfReaderEventStreamController.add(
        PdfPageChanged(detectedPageIndex + 1),
      );
    });

    if (_currentPageIndex != detectedPageIndex || _loadedPagesCache.isEmpty) {
      _currentPageIndex = detectedPageIndex;
      int cacheStartRange = _currentPageIndex - _bufferSize;
      int cacheEndRange = _currentPageIndex + _bufferSize;

      if (cacheStartRange < 0) cacheStartRange = 0;
      if (cacheEndRange >= widget.sizedPages.length) {
        cacheEndRange = widget.sizedPages.length - 1;
      }

      for (int index = cacheStartRange; index <= cacheEndRange; index++) {
        _initPageIntoCache(index);
      }

      final activeKeys = List<int>.from(_loadedPagesCache.keys);
      for (int index in activeKeys) {
        if (index < cacheStartRange || index > cacheEndRange) {
          _loadedPagesCache.remove(index);
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initPageIntoCache(0);
    widget.controller._userEvent.listen((event) {
      if (event is UserZoom) {
        _applyZoom(event.zoom);
      }
    });
  }

  // dispose
  @override
  void dispose() {
    _loadedPagesCache.clear();
    _transformationController.dispose();
    super.dispose();
  }

  final _transformationController = TransformationController();

  @override
  Widget build(BuildContext context) {
    final allSize = _loadedPagesCache.values.fold<int>(
      0,
      (previousValue, element) =>
          previousValue + (element == null ? 0 : element.length),
    );
    print(
      'cache size: ${_loadedPagesCache.length} size:${allSize.toFileSizeLabel()} - currentPage: $_currentPageIndex',
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        _buildLayout(constraints.maxWidth);
        _updateCurrentPageEvent(constraints.maxHeight, constraints.maxWidth);

        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _updateScrollPosition(
                event.scrollDelta.dy,
                constraints.maxHeight,
              );
            }
          },
          child: Container(
            color: Colors.grey[100],
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              children: [
                // 🚀 Cache ထဲမှာ တကယ်ရှိတဲ့ ၁၁ ရွက်ပဲ Render လုပ်တော့မယ်
                for (int activeIndex in _loadedPagesCache.keys) ...[
                  _buildPageItem(activeIndex, constraints.maxWidth),
                ],
                _scrollBar(constraints.maxHeight),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pageItem(int index) {
    final data = _loadedPagesCache[index];
    if (data != null) {
      return Image.memory(data);
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

  /// ************ Scrollbar Logic ***********
  double scrollbarDrapOffset = 0;
  bool _isDragging = false;
  double _currentScrollbarY = 0.0;

  double get currentZoom => widget.controller.currentZoom;

  void _applyZoom(double zoomValue) {
    if (widget.controller._currentZoom != zoomValue) {
      widget.controller._currentZoom = zoomValue;
      widget.controller._pdfReaderEventStreamController.add(
        PdfZoomChanged(zoomValue),
      );
    }

    // 🚀 Matrix4 သုံးစရာမလိုတော့ဘဲ setState လုပ်လိုက်တာနဲ့
    // Layout Engine က အချိုးကျ ကွက်တိ လိုက်ချဲ့ပေးသွားပါလိမ့်မယ်
    setState(() {});
  }
}
