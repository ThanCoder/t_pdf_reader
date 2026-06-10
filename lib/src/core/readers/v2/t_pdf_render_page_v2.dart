part of 't_pdf_reader_v2_base.dart';

class TPdfRenderPageV2 extends StatefulWidget {
  final PdfSizedPage sizedPage;
  final PdfBackgroundDocument document;
  final TPdfControllerV2 controller;
  const TPdfRenderPageV2({
    super.key,
    required this.sizedPage,
    required this.document,
    required this.controller,
  });

  @override
  State<TPdfRenderPageV2> createState() => _TPdfRenderPageV2State();
}

class _TPdfRenderPageV2State extends State<TPdfRenderPageV2> {
  Uint8List? imageBytes;
  bool isLoading = false;
  bool isVisible = false;
  String? error;

  void renderImage() async {
    try {
      if (imageBytes != null || isLoading || !isVisible) return;
      setState(() {
        isLoading = true;
        error = null;
      });
      final typeData = await widget.document.getPageImage(
        widget.sizedPage.index,
      );

      if (typeData != null) {
        imageBytes = typeData.materialize().asUint8List();
        // 🚀 ၂။ အဓိက သော့ချက် - ရလာတဲ့ Bytes ကို UI မှာ မပြခင် Flutter Memory ထဲ ကြိုတင် Decode လုပ်ခိုင်းခြင်း
        final imageProvider = MemoryImage(imageBytes!);
        if (!mounted) return;
        await precacheImage(imageProvider, context); // <--- ဒါလေး ခံပေးရပါမယ်
        // ok မှ image ထဲကို ထည့်မယ်
      }
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
  void initState() {
    super.initState();
    renderImage();
  }

  @override
  void dispose() {
    imageBytes = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print('width: ${widget.}')
    return VisibilityDetector(
      key: Key('pdf-page-${widget.sizedPage.index}'),
      onVisibilityChanged: (info) {
        // visibleFraction > 0 ဆိုတာ မျက်နှာပြင်ပေါ်မှာ စာမျက်နှာစပေါ်လာပြီလို့ ပြောတာပါ
        isVisible = info.visibleFraction > 0;
        widget.controller._currentPage = widget.sizedPage.index + 1;

        if (!widget.controller._pdfReaderEventStreamController.isClosed) {
          widget.controller._pdfReaderEventStreamController.add(
            PdfPageChanged(widget.controller._currentPage),
          );
        }
        renderImage();
      },
      child: // 🚀 ဒီနေရာမှာ အိအိလေး ကူးပြောင်းသွားအောင် Animation အုပ်လိုက်တာပါ
      Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeIn, // ဝင်လာရင် သုံးမည့် ပုံသဏ္ဍာန် Curve
          switchOutCurve:
              Curves.easeOut, // ထွက်သွားရင် သုံးမည့် ပုံသဏ္ဍာန် Curve
          child: _imageWidget,
        ),
      ),
    );
  }

  Widget get _imageWidget {
    if (isLoading) {
      return CircularProgressIndicator.adaptive();
    }
    if (error != null) {
      return Text(error!);
    }

    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        // fit: BoxFit.fill,
        // width: widget.sizedPage.width,
        height: widget.sizedPage.height,
        key: ValueKey('real-image-${widget.sizedPage.index}'),
      );
    }

    return Text(
      'Page ${widget.sizedPage.index + 1}',
      key: ValueKey('placeholder-text-${widget.sizedPage.index}'),
      style: const TextStyle(fontSize: 18, color: Colors.grey),
    );
  }
}
