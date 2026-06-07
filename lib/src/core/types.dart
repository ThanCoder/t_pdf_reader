// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:typed_data';

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
