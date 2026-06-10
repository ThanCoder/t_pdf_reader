part of 't_pdf_reader_base.dart';

class PdfReaderPage extends StatefulWidget {
  final String path;
  final int index;
  final PdfPage page;
  final PdfSizedPage sizedPage;
  final TPdfController controller;
  const PdfReaderPage({
    super.key,
    required this.path,
    required this.index,
    required this.page,
    required this.sizedPage,
    required this.controller,
  });

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
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
      await Future.microtask(() async {
        widget.page.loadPage();
        imageBytes = widget.page.getPdfImageAsync(
          renderImageErrorCallback: (error) => setState(() {
            this.error = error;
          }),
        );
        if (imageBytes != null) {
          // 🚀 ၂။ အဓိက သော့ချက် - ရလာတဲ့ Bytes ကို UI မှာ မပြခင် Flutter Memory ထဲ ကြိုတင် Decode လုပ်ခိုင်းခြင်း
          final imageProvider = MemoryImage(imageBytes!);
          if (!mounted) return;
          await precacheImage(imageProvider, context); // <--- ဒါလေး ခံပေးရပါမယ်
          // ok မှ image ထဲကို ထည့်မယ်
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
  void initState() {
    super.initState();
    renderImage();
    // print('init: ${widget.index}');
  }

  @override
  void dispose() {
    imageBytes = null;
    widget.page.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print('width: ${widget.}')
    return VisibilityDetector(
      key: Key('pdf-page-${widget.index}'),
      onVisibilityChanged: (info) {
        // visibleFraction > 0 ဆိုတာ မျက်နှာပြင်ပေါ်မှာ စာမျက်နှာစပေါ်လာပြီလို့ ပြောတာပါ
        isVisible = info.visibleFraction > 0;
        widget.controller._currentPage = widget.page.pageIndex + 1;

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
          duration: const Duration(
            milliseconds: 400,
          ), // Fade-in ဖြစ်မည့် ကြာချိန် (၃၀၀ မီလီစက္ကန့်)
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
        fit: BoxFit.fill,
        // width: widget.sizedPage.width,
        height: widget.sizedPage.height,
        key: ValueKey('real-image-${widget.index}'),
      );
    }

    return Text(
      'Page ${widget.index + 1}',
      key: ValueKey('placeholder-text-${widget.index}'),
      style: const TextStyle(fontSize: 18, color: Colors.grey),
    );
  }
}
