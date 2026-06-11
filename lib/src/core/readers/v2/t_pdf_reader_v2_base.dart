import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/core/low_levels/backgrounds/pdf_background_document.dart';
import 'package:t_pdf_reader/src/core/low_levels/classes/types.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';
import 'package:visibility_detector/visibility_detector.dart';

part 't_pdf_controller_v2.dart';
part 't_pdf_render_page_v2.dart';

class TPdfReaderV2 extends StatefulWidget {
  final String source;
  final String? password;
  final TPdfControllerV2 controller;
  const TPdfReaderV2({
    super.key,
    required this.source,
    this.password,
    required this.controller,
  });

  @override
  State<TPdfReaderV2> createState() => _TPdfReaderV2State();
}

class _TPdfReaderV2State extends State<TPdfReaderV2> {
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    document.close();
    scrollController.dispose();
    _transformationController.dispose();
    widget.controller._detachReader();
    super.dispose();
  }

  bool isLoading = false;
  String? error;
  List<PdfSizedPage> sizedPages = [];
  PdfBackgroundDocument document = PdfBackgroundDocument();
  final scrollController = ScrollController();
  final _transformationController = TransformationController();

  Future<void> init() async {
    try {
      final timer = Stopwatch()..start();
      setState(() {
        isLoading = true;
        error = null;
      });

      await document.openFile(widget.source, password: widget.password);

      sizedPages = await document.getSizedPage();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        timer.stop();

        widget.controller._attachReader(
          loadedElapsedTime: timer.elapsed,
          totalPage: sizedPages.length + 1,
        );
      });
      widget.controller._userEvent.listen((event) {
        if (event is UserJumpToPage) {
          _jumpToPageInternal(event.page - 1);
        }
        if (event is UserZoom) {
          _setZoom(event.zoom);
        }
      });

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      error = e.toString();
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: TextStyle(color: Colors.red)),
      );
    }
    return _listView;
  }

  Widget get _listView => Scrollbar(
    thumbVisibility: true,
    trackVisibility: true,
    controller: scrollController,
    interactive: true,
    child: LayoutBuilder(
      builder: (context, constraints) {
        // offset ပြန်တွက်မယ်
        _calculateOffsets(constraints.maxWidth);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _centerNativeView(constraints.maxWidth);
        });
        return InteractiveViewer(
          constrained: false,
          transformationController: _transformationController,
          minScale: widget.controller.minScale,
          maxScale: widget.controller.maxScale,
          scaleEnabled: widget.controller.scaleEnabled,
          panEnabled: widget.controller.panEnabled,
          panAxis: widget.controller.panAxis,
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: ListView.builder(
              // 🚀 Mouse Scroll ကို ကိုယ်တိုင် ထိန်းချုပ်ထားလို့ physics ကို Clamping ထားပေးရပါမယ်
              physics: const ClampingScrollPhysics(),
              itemCount: sizedPages.length,
              controller: scrollController,
              itemExtentBuilder: (index, dimensions) {
                final page = sizedPages[index];
                final aspectRatio = page.width / page.height;
                final pageHeight = constraints.maxWidth / aspectRatio;
                // return page.height * 0.5;
                return pageHeight;
              },
              itemBuilder: (context, index) => _pageItem(index),
            ),
          ),
        );
      },
    ),
  );

  Widget _pageItem(int index) {
    final sizedPage = sizedPages[index];
    return AspectRatio(
      aspectRatio: sizedPage.width / sizedPage.height,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Colors.orange)),
        child: TPdfRenderPageV2(
          sizedPage: sizedPage,
          document: document,
          controller: widget.controller,
        ),
      ),
    );
  }

  // ၁။ Controller သို့မဟုတ် State ထဲမှာ ဒါလေး ကြိုဆောက်ထားပါ
  List<double> pageOffsetsCache = [];

  // ၂။ PDF စဖွင့်ပြီး sizedPages တွေ ရလာကတည်းက ဒါကို တစ်ခါပဲ ကြိုတွက်ခိုင်းထားပါ
  void _calculateOffsets(double maxWidth) {
    double currentOffset = 0.0;
    pageOffsetsCache = [];

    for (var page in sizedPages) {
      pageOffsetsCache.add(currentOffset);
      final ratio = page.width / page.height;
      // တစ်ကယ့် height
      final pageHeight = maxWidth / ratio;

      currentOffset += pageHeight;
    }
  }

  void _jumpToPageInternal(int index) {
    if (index >= 0 && index < sizedPages.length) {
      final targetOffset = pageOffsetsCache[index];
      scrollController.jumpTo(targetOffset);
    }
    widget.controller._currentPage = index + 1;
    widget.controller._notifyListeners();
  }

  double get _currentZoom => _transformationController.value.row0.r;

  void _setZoom(double zoom) {
    // 🚀 ၁။ Screen ရဲ့ အကျယ်နဲ့ အမြင့် အလယ်ဗဟို (Center Offset) ကို ရှာခြင်း
    double centerX = 0.0;
    double centerY = 0.0;

    final screenSize = MediaQuery.of(context).size;
    centerX = screenSize.width / 2;
    centerY = screenSize.height / 2;

    // 🚀 ၂။ Center ကို ဗဟိုပြုပြီး ဇူးမ်ချဲ့မည့် Matrix4 သင်္ချာ ပုံသေနည်း
    final matrix = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(centerX, centerY) // ပြကွက်အလယ်ကို Pointer ရွှေ့မယ်
      // ignore: deprecated_member_use
      ..scale(zoom) // ချဲ့မယ်
      // ignore: deprecated_member_use
      ..translate(-centerX, -centerY); // မူလအနေအထား ပြန်ညှိမယ်

    _transformationController.value = matrix;
    widget.controller._currentZoom = zoom;
    if (!widget.controller._pdfReaderEventStreamController.isClosed) {
      widget.controller._pdfReaderEventStreamController.add(
        PdfZoomChanged(zoom),
      );
    }
  }

  void _centerNativeView(double maxWidth) {
    if (!mounted) return;
    _setZoom(_currentZoom);
    if (widget.controller._isReady) {
      // send pdf event
      if (!widget.controller._pdfReaderEventStreamController.isClosed) {
        widget.controller._pdfReaderEventStreamController.add(
          PdfScreenSizeChanged(_currentZoom, maxWidth),
        );
      }
    }
  }
}
