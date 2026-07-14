import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/reader/page_offset.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';
import 'package:than_pdf_engine/core/pdf_background_worker.dart';

class PageListItem extends StatefulWidget {
  final PageOffset page;
  final PdfBackgroundWorker pdfWorker;
  final TPdfController controller;
  final ReaderStateController readerStateController;
  const PageListItem({
    super.key,
    required this.page,
    required this.pdfWorker,
    required this.controller,
    required this.readerStateController,
  });

  @override
  State<PageListItem> createState() => _PageListItemState();
}

class _PageListItemState extends State<PageListItem> {
  Uint8List? lowImage;
  Uint8List? highImage;
  bool isLoading = false;
  Timer? _requestHighImageTimer;
  final imageDataChangeNotifier = ValueNotifier(1);
  StreamSubscription? _stateSubscription; // 💡 Stream ကို နားထောင်ဖို့
  bool _isReaderScrolling = false;

  @override
  void initState() {
    requestLowImage();
    super.initState();
    // 💡 Main State Stream ကို နားထောင်ပြီး controller ရဲ့ scrolling state ကို စောင့်ကြည့်မယ်
    // မင်းရဲ့ တကယ့် Code အရ stateStream ကို 'widget.controller' ကနေရရ၊ 'stateController' ကနေရရ ရတဲ့နေရာကနေ လှမ်းယူပါ
    // ဥပမာ - widget.controller.stateStream (သို့မဟုတ်) ရွေးချယ်ထားတဲ့ သင့်တော်ရာ stream
    _stateSubscription = widget.readerStateController.stateStream
        .map((s) => s.isScrolling)
        .distinct()
        .listen((isScrolling) {
          _isReaderScrolling = isScrolling;

          if (!isScrolling && highImage == null) {
            // 💡 Scroll လည်း ရပ်သွားပြီ၊ High Image လည်း မရှိသေးဘူးဆိုရင် တောင်းခိုင်းမယ်
            _requestHighImageTimer?.cancel();
            _requestHighImageTimer = Timer(
              const Duration(milliseconds: 200),
              () {
                requestHighImage();
              },
            );
          } else if (isScrolling) {
            // 💡 Scroll ဆွဲနေတုန်းဆိုရင် တောင်းဖို့ ပြင်ထားတဲ့ timer တွေကို လှမ်းဖျက်ပစ်မယ်
            _requestHighImageTimer?.cancel();
          }
        });
  }

  @override
  void didUpdateWidget(covariant PageListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.page.width != oldWidget.page.width ||
        widget.page.height != oldWidget.page.height) {
      highImage = null;
      _requestHighImageTimer?.cancel();
      requestHighImage();
    }
  }

  @override
  void dispose() {
    lowImage = null;
    highImage = null;
    _requestHighImageTimer?.cancel();
    _stateSubscription?.cancel();
    super.dispose();
  }

  void requestLowImage() async {
    try {
      if (isLoading || lowImage != null) return;
      setState(() {
        isLoading = true;
      });

      final res = await widget.pdfWorker.requestPageImageJpg(
        widget.page.pageIndex,
        width: widget.page.width,
        height: widget.page.height,
        quality: 20,
      );
      if (res != null) {
        lowImage = Uint8List.fromList(res.trans.materialize().asUint8List());
      }
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      // if (highImage == null) {
      //   _requestHighImageTimer?.cancel();
      //   _requestHighImageTimer = Timer(Duration(milliseconds: 300), () {
      //     requestHighImage();
      //   });
      // }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      debugPrint('[requestLowImage]: $e');
    }
  }

  void requestHighImage() async {
    try {
      if (_isReaderScrolling || isLoading || highImage != null) return;
      isLoading = true;

      final res = await widget.pdfWorker.requestPageImageJpg(
        widget.page.pageIndex,
        width: widget.page.width,
        height: widget.page.height,
        quality: 100,
      );
      if (res != null) {
        highImage = Uint8List.fromList(res.trans.materialize().asUint8List());
      }
      if (!mounted) return;
      isLoading = false;
      imageDataChangeNotifier.value += 1;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      debugPrint('[requestHighImage]: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.page.width,
      height: widget.page.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ValueListenableBuilder(
              valueListenable: imageDataChangeNotifier,
              builder: (context, value, child) {
                return imageWidget;
              },
            ),
          ),

          // footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: footerWidget,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget get footerWidget {
    if (widget.controller.pageFooterWidget != null) {
      return widget.controller.pageFooterWidget!(widget.page.pageIndex + 1);
    }
    return Text(
      'Page: ${widget.page.pageIndex + 1}',
      style: TextStyle(color: Colors.black),
    );
  }

  Widget get imageWidget {
    if (highImage != null) {
      return image(highImage!);
    }
    if (lowImage != null) {
      return image(lowImage!);
    }

    return const Center(child: CircularProgressIndicator.adaptive());
  }

  Widget image(Uint8List data) {
    return Image.memory(
      data,
      fit: BoxFit.fitWidth,
      gaplessPlayback: true,
      width: widget.page.width,
      height: widget.page.height,
    );
  }
}
