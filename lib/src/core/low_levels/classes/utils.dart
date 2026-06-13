part of 'pdf_document.dart';

/// get image
///
/// run in background
Future<Uint8List?> getPdfImage(
  String pdfPath,
  int index, {
  required int width,
  required int height,
  int quality = 100,
}) async {
  final bytes = await getPdfRawImage(
    pdfPath,
    index,
    width: width,
    height: height,
  );
  if (bytes == null) return null;
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: bytes.buffer,
    order: img.ChannelOrder.bgra,
  );
  return img.encodeJpg(image, quality: quality);
}

/// get raw image
///
/// run in background
Future<Uint8List?> getPdfRawImage(
  String pdfPath,
  int index, {
  required int width,
  required int height,
}) async {
  // 💡 Isolate ထဲမှာ သင့်ရဲ့ မူရင်း Native ကုဒ်ကို သုံးပြီး Background Thread နဲ့ ပုံဆွဲခြင်း
  return await Isolate.run<Uint8List?>(() {
    final pdf = getPdfium();
    pdf.FPDF_InitLibrary();
    // Pointer တွေကို try ပြင်ပမှာ ကြိုကြေညာထားမယ်
    PdfDocument? dom;
    Pointer<fpdf_page_t__> pagePtr = nullptr;
    Pointer<fpdf_bitmap_t__> bitmap = nullptr;

    try {
      // Isolate သီးသန့် Document နဲ့ Page Pointer ကို ခဏဖွင့်ခြင်း
      dom = PdfDocument();
      dom.openFile(pdfPath); // သင့် Document လမ်းကြောင်း
      pagePtr = pdf.FPDF_LoadPage(dom._domPtr, index);

      if (pagePtr == nullptr) return null;

      bitmap = pdf.FPDFBitmap_Create(width, height, 0);
      pdf.FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
      pdf.FPDF_RenderPageBitmap(bitmap, pagePtr, 0, 0, width, height, 0, 0);

      final buffer = pdf.FPDFBitmap_GetBuffer(bitmap);
      final int stride = pdf.FPDFBitmap_GetStride(bitmap);
      final int bufferLength = stride * height;

      // 1. Native bytes ကို Dart Uint8List view အဖြစ် ပြောင်းတယ်
      final Uint8List rawBytes = buffer.cast<Uint8>().asTypedList(bufferLength);

      // 2. Isolate အချင်းချင်း safe ဖြစ်ဖြစ် မြန်မြန်ဆန်ဆန် ပို့နိုင်အောင် အသွင်ပြောင်းတယ်
      final transferable = TransferableTypedData.fromList([rawBytes]);

      // 3. Main isolate ဘက်မှာ ပြန်သုံးလို့ရအောင် bytes ထုတ်ယူတယ်
      return transferable.materialize().asUint8List();
    } catch (e) {
      return null;
    } finally {
      pdf.FPDFBitmap_Destroy(bitmap);
      pdf.FPDF_ClosePage(pagePtr);
      dom?.close();

      pdf.FPDF_DestroyLibrary();
    }
  });
}

Future<List<PdfSizedPage>> getPdfSizedPagesWithLowSizeImages(
  String pdfPath, {
  required List<PdfSizedPage> sizedPageList,
  int quality = 50,
  double zoom = 0.2,
}) async {
  return await Isolate.run<List<PdfSizedPage>>(() {
    final pdf = getPdfium();
    pdf.FPDF_InitLibrary();
    final list = <PdfSizedPage>[];
    PdfDocument? dom;
    Pointer<fpdf_page_t__> pagePtr = nullptr;
    Pointer<fpdf_bitmap_t__> bitmap = nullptr;

    try {
      // Isolate သီးသန့် Document နဲ့ Page Pointer ကို ခဏဖွင့်ခြင်း
      dom = PdfDocument();
      dom.openFile(pdfPath); // သင့် Document လမ်းကြောင်း

      for (var page in sizedPageList) {
        pagePtr = pdf.FPDF_LoadPage(dom._domPtr, page.index);
        if (pagePtr == nullptr) return list;

        final width = (page.width * zoom).toInt();
        final height = (page.height * zoom).toInt();

        bitmap = pdf.FPDFBitmap_Create(width, height, 0);
        pdf.FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
        pdf.FPDF_RenderPageBitmap(bitmap, pagePtr, 0, 0, width, height, 0, 0);

        final buffer = pdf.FPDFBitmap_GetBuffer(bitmap);
        final int stride = pdf.FPDFBitmap_GetStride(bitmap);
        final int bufferLength = stride * height;

        final Uint8List rawBytes = buffer.cast<Uint8>().asTypedList(
          bufferLength,
        );
        final Uint8List result = Uint8List.fromList(rawBytes);
        final image = img.Image.fromBytes(
          width: width,
          height: height,
          bytes: result.buffer,
          order: img.ChannelOrder.bgra,
        );
        final jpg = img.encodeJpg(image, quality: quality);
        list.add(page.copyWith(lowBytes: jpg));
      }
      return list;
    } catch (e) {
      return [];
    } finally {
      pdf.FPDFBitmap_Destroy(bitmap);
      pdf.FPDF_ClosePage(pagePtr);
      dom?.close();
      pdf.FPDF_DestroyLibrary();
    }
  });
}

/// get sized page list
///
/// run in background
Future<List<PdfSizedPage>> getPagesAsyncFile(
  String path, {
  String? password,
}) async {
  return await Isolate.run<List<PdfSizedPage>>(() {
    final pdf = getPdfium();
    pdf.FPDF_InitLibrary();

    final dom = PdfDocument();
    dom.openFile(path, password: password);
    final count = dom.pageCount;

    List<PdfSizedPage> list = [];
    for (var i = 0; i < count; i++) {
      // Object အသစ်တွေ ထပ်မဆောက်တော့ဘဲ native pointer ကို တိုက်ရိုက် load လုပ်ပါတယ်
      final pagePtr = pdf.FPDF_LoadPage(dom._domPtr, i);

      if (pagePtr != nullptr) {
        final width = pdf.FPDF_GetPageWidth(pagePtr);
        final height = pdf.FPDF_GetPageHeight(pagePtr);
        list.add(PdfSizedPage(index: i, width: width, height: height));

        pdf.FPDF_ClosePage(pagePtr); // သုံးပြီးတာနဲ့ ချက်ချင်းပိတ်
      }
    }
    dom.close();

    return list;
  });
}

///
/// ### run in background thread or isolate
///
/// run in background
Future<List<PdfSizedPage>> getPagesAsyncFileSpeedUp(
  String path, {
  String? password,
}) async {
  return await Isolate.run<List<PdfSizedPage>>(() {
    final pdf = getPdfium();
    pdf.FPDF_InitLibrary();

    final dom = PdfDocument();
    dom.openFile(path, password: password);
    final count = dom.pageCount;

    // 🚀 မန်မိုရီ နေရာကို ကြိုသတ်မှတ်ထားခြင်းဖြင့် Array ဆွဲဆန့်ရတဲ့ Overhead ကို လျှော့ချပါတယ်
    final List<PdfSizedPage> list = List<PdfSizedPage>.generate(
      count,
      (i) => PdfSizedPage(index: i, width: 0, height: 0), // Dummy init
    );

    // FPDF_GetPageSizeByIndex အတွက် double တန်ဖိုးလက်ခံမည့် Native Memory Pointer ကြိုဆောက်ခြင်း
    final Pointer<Double> widthPtr = calloc<Double>();
    final Pointer<Double> heightPtr = calloc<Double>();

    try {
      for (var i = 0; i < count; i++) {
        // 🔥 Loaded Page မလိုတော့ဘူး! Index အလိုက် Size ကို တိုက်ရိုက် တောင်းပါတယ်
        // ဒီကောင်က စာမျက်နှာ ၃ သန်းကို စက္ကန့်ပိုင်းအတွင်း တွက်ထုတ်ပေးနိုင်ပါတယ်
        final int result = pdf.FPDF_GetPageSizeByIndex(
          dom._domPtr,
          i,
          widthPtr,
          heightPtr,
        );

        if (result != 0) {
          list[i] = PdfSizedPage(
            index: i,
            width: widthPtr.value,
            height: heightPtr.value,
          );
        }
      }
    } finally {
      // Native Memory တွေကို သေချာ ပြန်ဖျက်ပေးရပါမယ် (Memory Leak ကာကွယ်ရန်)
      calloc.free(widthPtr);
      calloc.free(heightPtr);
      dom.close();
      pdf.FPDF_InitLibrary();
    }

    return list;
  });
}
