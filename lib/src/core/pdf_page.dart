// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfium_dart/pdfium_dart.dart';

typedef PdfPageRenderImageErrorCallback = void Function(String error);

class PdfPage {
  final _pdf = getPdfium();
  final Pointer<fpdf_document_t__> domPtr;
  int _pageIndex = -1;
  Pointer<fpdf_page_t__> _page = nullptr;
  double _width = -1;
  double _height = -1;
  int get pageIndex => _pageIndex;

  PdfPage({required this.domPtr, required this._pageIndex});

  void loadPage() {
    _page = _pdf.FPDF_LoadPage(domPtr, pageIndex);
    _width = pageWidth;
    _height = pageHeight;
  }

  void loadPageIndex(int pageIndex) {
    _pageIndex = pageIndex;
    _page = _pdf.FPDF_LoadPage(domPtr, pageIndex);
    _width = pageWidth;
    _height = pageHeight;
  }

  double get pageHeight {
    if (_height != -1) return _height;
    if (_page == nullptr) return -1;
    return _pdf.FPDF_GetPageHeight(_page);
  }

  double get pageWidth {
    if (_width != -1) return _width;
    if (_page == nullptr) return -1;
    return _pdf.FPDF_GetPageWidth(_page);
  }

  void close() {
    if (_page == nullptr) return;
    _pdf.FPDF_ClosePage(_page);
  }

  Uint8List? getPdfImage({
    int quality = 100,
    double zoom = 1.0,
    PdfPageRenderImageErrorCallback? renderImageErrorCallback,
  }) {
    final rawImg = renderPageRawImage(
      zoom: zoom,
      renderImageErrorCallback: renderImageErrorCallback,
    );
    if (rawImg == null) return null;
    final image = img.Image.fromBytes(
      width: (pageWidth * zoom).toInt(),
      height: (pageHeight * zoom).toInt(),
      bytes: rawImg.buffer,
      order: img.ChannelOrder.bgra,
    );
    return img.encodeJpg(image, quality: quality);
  }

  /// bytes for BGRA (Not png,jpg) Image!
  Uint8List? renderPageRawImage({
    int rotate = 0,
    int flags = 0,
    double zoom =
        1.0, // 🚀 ၁. Zoom တန်ဖိုးကို Default 1.0 (100%) အဖြစ် လက်ခံမယ်
    PdfPageRenderImageErrorCallback? renderImageErrorCallback,
  }) {
    Pointer<fpdf_bitmap_t__> bitmap = nullptr;
    try {
      // 🚀 ၂. Zoom အလိုက် ပုံထွက်လာမည့် Width နှင့် Height အမှန်ကို တွက်ချက်ခြင်း
      final int renderedWidth = (pageWidth * zoom).toInt();
      final int renderedHeight = (pageHeight * zoom).toInt();

      bitmap = _pdf.FPDFBitmap_Create(renderedWidth, renderedHeight, 0);
      if (bitmap == nullptr) {
        throw Exception("Failed to create FPDFBitmap");
      }
      _pdf.FPDFBitmap_FillRect(
        bitmap,
        0,
        0,
        renderedWidth,
        renderedHeight,
        0xFFFFFFFF,
      );

      // ၃။ သင့်ရဲ့ Function ကို သုံးပြီး Bitmap ပေါ်ကို PDF Content တွေ Render လုပ်ပါမယ်
      _pdf.FPDF_RenderPageBitmap(
        bitmap,
        _page,
        0, // start_x (ဘယ်ဘက် အစွန်းဆုံးက စဆွဲမယ်)
        0, // start_y (အပေါ်ဘက် အစွန်းဆုံးက စဆွဲမယ်)
        renderedWidth, // size_x
        renderedHeight, // size_y
        rotate, // 0, 1, 2, 3
        flags, // e.g., 0 သို့မဟုတ် FPDF_ANNOT
      );
      final buffer = _pdf.FPDFBitmap_GetBuffer(bitmap);

      // ပုံရဲ့ data အရွယ်အစားကို တွက်ချက်ခြင်း (Width * Height * 4 bytes for BGRA)
      final int stride = _pdf.FPDFBitmap_GetStride(bitmap);
      final int bufferLength = stride * renderedHeight;

      // Pointer Data ကို Dart ရဲ့ Uint8List (Byte Array) အဖြစ် ပြောင်းလဲခြင်း
      final Uint8List rawBytes = buffer.cast<Uint8>().asTypedList(bufferLength);

      return Uint8List.fromList(rawBytes);
    } catch (e) {
      if (renderImageErrorCallback != null) {
        renderImageErrorCallback.call(e.toString());
      } else {
        debugPrint('[PdfPage:renderPageImage] $e');
      }

      return null;
    } finally {
      if (bitmap != nullptr) {
        _pdf.FPDFBitmap_Destroy(bitmap);
      }
    }
  }
}
