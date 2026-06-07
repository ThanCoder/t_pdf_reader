import 'dart:async';
import 'dart:isolate';

import 'package:dart_core_extensions/dart_core_extensions.dart';
import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/core/pdf_document.dart';
import 'package:t_pdf_reader/src/core/pdf_page.dart';
import 'package:t_pdf_reader/src/core/pdf_reader_page.dart';
import 'package:t_pdf_reader/src/core/t_pdf_controller.dart';
import 'package:t_pdf_reader/src/core/types.dart';

class TPdfReader extends StatefulWidget {
  final String source;
  final String? password;
  final TPdfController controller;
  const TPdfReader({
    super.key,
    required this.source,
    this.password,
    required this.controller,
  });

  @override
  State<TPdfReader> createState() => _TPdfReaderState();
}

class _TPdfReaderState extends State<TPdfReader> {
  @override
  void initState() {
    super.initState();
    widget.controller.attachTransformationController(_transformationController);
    init();
  }

  @override
  void dispose() {
    document.close();
    scrollController.dispose();
    _transformationController.dispose();
    lowImageIsolate?.kill(priority: Isolate.immediate);
    lowImageIsolate = null;
    super.dispose();
  }

  Future<void> init() async {
    try {
      final timer = Stopwatch()..start();
      setState(() {
        isLoading = true;
        error = null;
      });

      document.openFile(widget.source, password: widget.password);

      sizedPages = await PdfDocument.getPagesAsyncFileSpeedUp(
        widget.source,
        password: widget.password,
      );
      _calculateOffsets();
      // low bytes ရယူမယ်
      _addLowImageBytesStream();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        timer.stop();

        widget.controller.attachReader(
          loadedElapsedTime: timer.elapsed,
          totalPage: sizedPages.length + 1,
          jumpToPageClosure: (page) {
            _jumpToPageInternal(page - 1);
          },
          zoomToPageCallback: (zoom) {
            // 🚀 ၁။ Screen ရဲ့ အကျယ်နဲ့ အမြင့် အလယ်ဗဟို (Center Offset) ကို ရှာခြင်း
            double centerX = 0.0;
            double centerY = 0.0;

            final screenSize = MediaQuery.of(context).size;
            centerX = screenSize.width / 2;
            centerY = screenSize.height / 2;

            // 🚀 ၂။ Center ကို ဗဟိုပြုပြီး ဇူးမ်ချဲ့မည့် Matrix4 သင်္ချာ ပုံသေနည်း
            final matrix = Matrix4.identity()
              ..translate(centerX, centerY) // ပြကွက်အလယ်ကို Pointer ရွှေ့မယ်
              ..scale(zoom) // ချဲ့မယ်
              ..translate(-centerX, -centerY); // မူလအနေအထား ပြန်ညှိမယ်

            _transformationController.value = matrix;
          },
        );
      });

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      // debugPrint('[TPdfReader:init]: $e');
      error = e.toString();
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  bool isLoading = false;
  String? error;
  List<PdfSizedPage> sizedPages = [];
  PdfDocument document = PdfDocument();
  final scrollController = ScrollController();
  final _transformationController = TransformationController();

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
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) => _listView,
    );
  }

  Widget get _listView => Scrollbar(
    thumbVisibility: true,
    trackVisibility: true,
    controller: scrollController,
    interactive: true,
    child: LayoutBuilder(
      builder: (context, constraints) {
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
                return page.height * 0.5;
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
    final page = PdfPage(domPtr: document.domPtr, pageIndex: index);
    return AnimatedOpacity(
      opacity: 1,
      duration: Duration(milliseconds: 1800),
      child: SizedBox(
        width: sizedPage.width,
        height: sizedPage.height,
        child: PdfReaderPage(
          path: widget.source,
          index: index,
          page: page,
          sizedPage: sizedPage,
          controller: widget.controller,
        ),
      ),
    );
  }

  // ၁။ Controller သို့မဟုတ် State ထဲမှာ ဒါလေး ကြိုဆောက်ထားပါ
  List<double> pageOffsetsCache = [];

  // ၂။ PDF စဖွင့်ပြီး sizedPages တွေ ရလာကတည်းက ဒါကို တစ်ခါပဲ ကြိုတွက်ခိုင်းထားပါ
  void _calculateOffsets() {
    double currentOffset = 0.0;
    pageOffsetsCache = [];

    for (var page in sizedPages) {
      pageOffsetsCache.add(currentOffset);
      currentOffset +=
          page.height * 0.5; // စာမျက်နှာအမြင့်တွေကို တန်းစီပေါင်းသွားခြင်း
    }
  }

  void _jumpToPageInternal(int index) {
    if (index >= 0 && index < sizedPages.length) {
      final targetOffset = pageOffsetsCache[index];
      scrollController.jumpTo(targetOffset);
    }
  }

  Isolate? lowImageIsolate;

  /// Low image bytes တွေကို Stream နဲ့ တဖြည်းဖြည်းချင်း တွက်ပြီး ထည့်သွားမည့် Function
  Future<void> _addLowImageBytesStream() async {
    // await getPdfSizedPagesWithLowSizeImagesInBackgound(
    //   widget.source,
    //   sizedPageList: sizedPages,
    //   onBackgroundStartRunning: (isolate) {
    //     lowImageIsolate = isolate;
    //   },
    //   progressStream: widget.controller.lowImageProgressStream,
    // );
    // sizedPages = await getPdfSizedPagesWithLowSizeImages(
    //   widget.source,
    //   sizedPageList: sizedPages,
    // );
    // setState(() {});
    // print('loaded low image');
  }
}
