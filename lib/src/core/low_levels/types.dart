// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:ffi';
import 'dart:typed_data';

import 'package:pdfium_dart/pdfium_dart.dart';

class PdfSizedPage {
  final double width;
  final int index;
  final double height;
  Uint8List? lowBytes;
  PdfSizedPage({
    required this.index,
    required this.width,
    required this.height,
    this.lowBytes,
  });

  PdfSizedPage copyWith({
    double? width,
    int? index,
    double? height,
    Uint8List? lowBytes,
  }) {
    return PdfSizedPage(
      width: width ?? this.width,
      index: index ?? this.index,
      height: height ?? this.height,
      lowBytes: lowBytes ?? this.lowBytes,
    );
  }
}

/// ### Need To Destory -> `bitmap` pointer
class PdfPageBitmapPointerResult {
  final int address; // Pixel Buffer ရဲ့ Memory Address
  final int bufferLength; // Buffer ရဲ့ Size (Bytes count)
  final int width; // ပုံရဲ့ အကျယ်
  final int height;
  final Pointer<fpdf_bitmap_t__> bitmapPointer;
  PdfPageBitmapPointerResult({
    required this.address,
    required this.bufferLength,
    required this.width,
    required this.height,
    required this.bitmapPointer,
  });
}
