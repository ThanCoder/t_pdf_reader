import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'package:pdfium_dart/pdfium_dart.dart';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:t_pdf_reader/src/core/low_levels/classes/types.dart';
import 'dart:async';
import 'dart:isolate';

part 'pdf_page.dart';
part 'utils.dart';

typedef PdfOpenErrorCallback = void Function(String error);

class PdfDocument {
  final _pdf = getPdfium();
  Pointer<fpdf_document_t__> _domPtr = nullptr;

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

      if (_domPtr == nullptr) {
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
    if (_domPtr == nullptr) return [];
    List<PdfPage> list = [];
    for (var i = 0; i < pageCount; i++) {
      final page = PdfPage(domPtr: _domPtr, pageIndex: i);
      page.loadPage();
      list.add(page);
      page.close();
    }
    return list;
  }

  /// create pdf page without call -> `[load]` method
  PdfPage getPageWithoutLoad(int pageIndex) {
    return PdfPage(domPtr: _domPtr, pageIndex: pageIndex);
  }

  /// create page with called -> `[load]` method
  PdfPage getPage(int pageIndex) {
    final page = PdfPage(domPtr: _domPtr, pageIndex: pageIndex);
    page.loadPage();
    return page;
  }

  Uint8List? getPageImage(
    int pageIndex, {
    int quality = 100,
    double zoom = 1.0,
    PdfPageRenderImageErrorCallback? renderImageErrorCallback,
  }) {
    final page = getPage(pageIndex);
    return page.getPdfImageAsync(
      quality: quality,
      zoom: zoom,
      renderImageErrorCallback: renderImageErrorCallback,
    );
  }

  /// page count
  int get pageCount {
    if (_domPtr == nullptr) return 0;
    return _pdf.FPDF_GetPageCount(_domPtr);
  }

  void close() {
    if (_domPtr == nullptr) return;
    _pdf.FPDF_CloseDocument(_domPtr);
    // _pdf.FPDF_DestroyLibrary();
  }
}
