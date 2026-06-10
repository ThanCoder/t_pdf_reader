// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:t_pdf_reader/src/core/low_levels/types.dart';

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

  // Future<Uint8List?> getPdfImage({
  //   int quality = 100,
  //   double zoom = 1.0,
  //   PdfPageRenderImageErrorCallback? renderImageErrorCallback,
  // }) async {
  //   return await Future.microtask(() {
  //     return getPdfImageAsync(
  //       renderImageErrorCallback: renderImageErrorCallback,
  //       quality: quality,
  //       zoom: zoom,
  //     );
  //   });
  // }

  Uint8List? getPdfImageAsync({
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

  /// You Need To Destory -> pointer
  PdfPageBitmapPointerResult? renderBigmapPointer({
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
        0,
        0,
        renderedWidth,
        renderedHeight,
        rotate,
        flags,
      );
      // 🚀 Pointer ကို ယူမယ် (Copy မကူးတော့ပါ)
      final Pointer<Void> buffer = _pdf.FPDFBitmap_GetBuffer(bitmap);
      final int stride = _pdf.FPDFBitmap_GetStride(bitmap);
      final int bufferLength = stride * renderedHeight;

      return PdfPageBitmapPointerResult(
        address: buffer.address,
        bufferLength: bufferLength,
        width: renderedWidth,
        height: renderedHeight,
        bitmapPointer: bitmap,
      );
    } catch (e) {
      if (renderImageErrorCallback != null) {
        renderImageErrorCallback.call(e.toString());
      } else {
        debugPrint('[PdfPage:renderPageImage] $e');
      }
      return null;
    }
  }

  /// ### bytes for BGRA (Not png,jpg) Image!
  Uint8List? renderPageRawImage({
    int rotate = 0,
    int flags = 0,
    double zoom = 1.0,
    PdfPageRenderImageErrorCallback? renderImageErrorCallback,
  }) {
    Pointer<fpdf_bitmap_t__> bitmap = nullptr;
    try {
      final pointerResult = renderBigmapPointer(
        flags: flags,
        rotate: rotate,
        zoom: zoom,
        renderImageErrorCallback: renderImageErrorCallback,
      );
      if (pointerResult == null) return null;
      bitmap = pointerResult.bitmapPointer;
      final nativeBuffer = Pointer<Uint8>.fromAddress(pointerResult.address);

      // Pointer Data ကို Dart ရဲ့ Uint8List (Byte Array) အဖြစ် ပြောင်းလဲခြင်း
      final Uint8List rawBytes = nativeBuffer.asTypedList(
        pointerResult.bufferLength,
      );

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
