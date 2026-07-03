import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/reader/page_offset.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PageListItem extends StatefulWidget {
  final PageOffset page;
  final PdfBackgroundWorker pdfWorker;
  final TPdfController controller;
  const PageListItem({
    super.key,
    required this.page,
    required this.pdfWorker,
    required this.controller,
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

  @override
  void initState() {
    requestLowImage();
    super.initState();
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
        lowImage = Uint8List.fromList(res.materialize().asUint8List());
      }
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      if (highImage == null) {
        _requestHighImageTimer?.cancel();
        _requestHighImageTimer = Timer(Duration(milliseconds: 300), () {
          requestHighImage();
        });
      }
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
      if (isLoading || highImage != null) return;
      isLoading = true;

      final res = await widget.pdfWorker.requestPageImageJpg(
        widget.page.pageIndex,
        width: widget.page.width,
        height: widget.page.height,
        quality: 100,
      );
      if (res != null) {
        highImage = Uint8List.fromList(res.materialize().asUint8List());
      }
      if (!mounted) return;
      isLoading = false;
      imageDataChangeNotifier.value += imageDataChangeNotifier.value;
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
      child: Column(
        children: [
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: imageDataChangeNotifier,
              builder: (context, value, child) {
                return imageWidget;
              },
            ),
          ),
          if (widget.controller.pageFooterWidget != null)
            widget.controller.pageFooterWidget!(widget.page.pageIndex + 1)
          else
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Page: ${widget.page.pageIndex + 1}',
                style: TextStyle(color: Colors.black),
              ),
            ),
        ],
      ),
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
