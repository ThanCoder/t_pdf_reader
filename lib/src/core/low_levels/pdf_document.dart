// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:pdfium_dart/pdfium_dart.dart';

import 'package:t_pdf_reader/src/core/low_levels/pdf_page.dart';
import 'package:t_pdf_reader/src/core/low_levels/types.dart';

typedef PdfOpenErrorCallback = void Function(String error);

class PdfDocument {
  final _pdf = getPdfium();

  Pointer<fpdf_document_t__> _domPtr = nullptr;

  Pointer<fpdf_document_t__> get domPtr => _domPtr;

  void openFile(
    String path, {
    String? password,
    PdfOpenErrorCallback? openErrorFun,
  }) {
    _pdf.FPDF_InitLibrary();

    final filePathPtr = path.toNativeUtf8();
    final Pointer<Utf8> passPtr = (password != null)
        ? password.toNativeUtf8()
        : nullptr;

    try {
      _domPtr = _pdf.FPDF_LoadDocument(
        filePathPtr.cast<Char>(),
        passPtr.cast<Char>(),
      );

      if (domPtr == nullptr) {
        final errorCode = _pdf.FPDF_GetLastError();

        if (openErrorFun != null) {
          openErrorFun('PDF Open Error: Erro Code `$errorCode`');
        } else {
          throw Exception('PDF Open Error: Erro Code `$errorCode`');
        }
      }
    } catch (e) {
      if (openErrorFun != null) {
        openErrorFun(e.toString());
      } else {
        rethrow;
      }
    } finally {
      malloc.free(filePathPtr);
      if (passPtr != nullptr) {
        malloc.free(passPtr);
      }
    }
  }

  List<PdfPage> getPages() {
    if (domPtr == nullptr) return [];
    List<PdfPage> list = [];
    for (var i = 0; i < pageCount; i++) {
      final page = PdfPage(domPtr: domPtr, pageIndex: i);
      page.loadPage();
      list.add(page);
      page.close();
    }
    return list;
  }

  Uint8List? getPageImage(
    int pageIndex, {
    int quality = 100,
    double zoom = 1.0,
    PdfPageRenderImageErrorCallback? renderImageErrorCallback,
  }) {
    final page = PdfPage(domPtr: domPtr, pageIndex: pageIndex);
    page.loadPage();
    return page.getPdfImageAsync(
      quality: quality,
      zoom: zoom,
      renderImageErrorCallback: renderImageErrorCallback,
    );
  }

  /// page count
  int get pageCount {
    if (domPtr == nullptr) return 0;
    return _pdf.FPDF_GetPageCount(domPtr);
  }

  void close() {
    if (domPtr == nullptr) return;
    _pdf.FPDF_CloseDocument(domPtr);
  }

  static Future<List<PdfSizedPage>> getPagesAsyncFile(
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
        final pagePtr = pdf.FPDF_LoadPage(dom.domPtr, i);

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
  static Future<List<PdfSizedPage>> getPagesAsyncFileSpeedUp(
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
            dom.domPtr,
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
      }

      return list;
    });
  }
}
