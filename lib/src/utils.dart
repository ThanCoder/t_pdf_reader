import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dart_core_extensions/dart_core_extensions.dart';
import 'package:image/image.dart' as img;
import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:t_pdf_reader/src/core/pdf_document.dart';
import 'package:t_pdf_reader/src/core/types.dart';

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

Future<Uint8List?> getPdfRawImage(
  String pdfPath,
  int index, {
  required int width,
  required int height,
}) async {
  try {
    // 💡 Isolate ထဲမှာ သင့်ရဲ့ မူရင်း Native ကုဒ်ကို သုံးပြီး Background Thread နဲ့ ပုံဆွဲခြင်း
    return await Isolate.run<Uint8List?>(() {
      final pdf = getPdfium();
      pdf.FPDF_InitLibrary();

      // Isolate သီးသန့် Document နဲ့ Page Pointer ကို ခဏဖွင့်ခြင်း
      final dom = PdfDocument();
      dom.openFile(pdfPath); // သင့် Document လမ်းကြောင်း
      final pagePtr = pdf.FPDF_LoadPage(dom.domPtr, index);

      if (pagePtr == nullptr) return null;

      final bitmap = pdf.FPDFBitmap_Create(width, height, 0);
      pdf.FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
      pdf.FPDF_RenderPageBitmap(bitmap, pagePtr, 0, 0, width, height, 0, 0);

      final buffer = pdf.FPDFBitmap_GetBuffer(bitmap);
      final int stride = pdf.FPDFBitmap_GetStride(bitmap);
      final int bufferLength = stride * height;

      final Uint8List rawBytes = buffer.cast<Uint8>().asTypedList(bufferLength);
      final Uint8List result = Uint8List.fromList(rawBytes);

      pdf.FPDFBitmap_Destroy(bitmap);
      pdf.FPDF_ClosePage(pagePtr);
      dom.close();

      return result;
    });
  } catch (e) {
    return null;
  }
}

Future<List<PdfSizedPage>> getPdfSizedPagesWithLowSizeImages(
  String pdfPath, {
  required List<PdfSizedPage> sizedPageList,
  int quality = 50,
  double zoom = 0.2,
}) async {
  try {
    // 💡 Isolate ထဲမှာ သင့်ရဲ့ မူရင်း Native ကုဒ်ကို သုံးပြီး Background Thread နဲ့ ပုံဆွဲခြင်း
    return await Isolate.run<List<PdfSizedPage>>(() {
      final pdf = getPdfium();
      pdf.FPDF_InitLibrary();
      final list = <PdfSizedPage>[];

      // Isolate သီးသန့် Document နဲ့ Page Pointer ကို ခဏဖွင့်ခြင်း
      final dom = PdfDocument();
      dom.openFile(pdfPath); // သင့် Document လမ်းကြောင်း

      for (var page in sizedPageList) {
        final pagePtr = pdf.FPDF_LoadPage(dom.domPtr, page.index);
        if (pagePtr == nullptr) return list;

        final width = (page.width * zoom).toInt();
        final height = (page.height * zoom).toInt();

        final bitmap = pdf.FPDFBitmap_Create(width, height, 0);
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

        pdf.FPDFBitmap_Destroy(bitmap);
        pdf.FPDF_ClosePage(pagePtr);

        print('loaded page: ${page.index}');
      }

      dom.close();

      return list;
    });
  } catch (e) {
    return [];
  }
}

/// progressStream (total,loaded)
Future<void> getPdfSizedPagesWithLowSizeImagesInBackgound(
  String pdfPath, {
  required List<PdfSizedPage> sizedPageList,
  void Function(Isolate isolate)? onBackgroundStartRunning,

  StreamController<(int, int)>? progressStream,
  int quality = 50,
  double zoom = 0.2,
}) async {
  final totalPages = sizedPageList.length;

  final receivePort = ReceivePort();
  final isolate = await Isolate.spawn(
    _getPdfSizedPagesWithLowSizeImagesInBackgound,
    (receivePort.sendPort, pdfPath, quality, zoom, totalPages),
  );
  onBackgroundStartRunning?.call(isolate);

  await for (var msg in receivePort) {
    if (msg is Map<String, dynamic>) {
      final loadedIndex = msg.getInt(['index']);

      TransferableTypedData transferable = msg['bytes'];
      final data = transferable.materialize().asUint8List();
      sizedPageList[loadedIndex].lowBytes = data;

      progressStream?.add((sizedPageList.length, loadedIndex + 1));
      print('loaded: ${loadedIndex + 1}/${sizedPageList.length}');

      // စာမျက်နှာအကုန်လုံး တွက်ပြီးသွားရင် await for loop ကြီးထဲကနေ ထွက်ဖို့ Port ကို ပိတ်လိုက်မယ်
      if (loadedIndex + 1 == totalPages) {
        receivePort.close();
        progressStream?.close();
      }
    }
  }
}

void _getPdfSizedPagesWithLowSizeImagesInBackgound(
  (SendPort, String, int, double, int) args,
) async {
  final sendPort = args.$1;
  try {
    final pdfPath = args.$2;
    final quality = args.$3;
    final zoom = args.$4;
    final count = args.$5;

    final pdf = getPdfium();
    pdf.FPDF_InitLibrary();

    // Isolate သီးသန့် Document နဲ့ Page Pointer ကို ခဏဖွင့်ခြင်း
    final dom = PdfDocument();
    dom.openFile(pdfPath); // သင့် Document လမ်းကြောင်း

    for (var index = 0; index < count; index++) {
      final pagePtr = pdf.FPDF_LoadPage(dom.domPtr, index);
      if (pagePtr == nullptr) continue;
      final pageW = pdf.FPDF_GetPageHeight(pagePtr);
      final pageH = pdf.FPDF_GetPageWidth(pagePtr);

      final width = (pageW * zoom).toInt();
      final height = (pageH * zoom).toInt();

      final bitmap = pdf.FPDFBitmap_Create(width, height, 0);
      pdf.FPDFBitmap_FillRect(bitmap, 0, 0, width, height, 0xFFFFFFFF);
      pdf.FPDF_RenderPageBitmap(bitmap, pagePtr, 0, 0, width, height, 0, 0);

      final buffer = pdf.FPDFBitmap_GetBuffer(bitmap);
      final int stride = pdf.FPDFBitmap_GetStride(bitmap);
      final int bufferLength = stride * height;

      final Uint8List rawBytes = buffer.cast<Uint8>().asTypedList(bufferLength);
      final Uint8List result = Uint8List.fromList(rawBytes);
      final image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: result.buffer,
        order: img.ChannelOrder.bgra,
      );
      final jpg = img.encodeJpg(image, quality: quality);

      pdf.FPDFBitmap_Destroy(bitmap);
      pdf.FPDF_ClosePage(pagePtr);

      final transferableBytes = TransferableTypedData.fromList([jpg]);

      // ၂။ Map ထဲမှာ ထည့်ပြီး Main Isolate ဆီ လှမ်းပို့မယ်
      sendPort.send({
        'index': index,
        'bytes': transferableBytes, // <--- ဒါကို ပို့လိုက်တာပါ
      });
      // print('loaded: ${index}');
    }

    dom.close();
  } catch (e) {
    print('[_getPdfSizedPagesWithLowSizeImagesInBackgound]: $e');
  }
}
