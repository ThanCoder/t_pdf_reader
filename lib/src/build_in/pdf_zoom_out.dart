import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfZoomOut extends StatelessWidget {
  const PdfZoomOut({super.key, required this.controller});
  final TPdfController controller;

  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;
    return IconButton(
      style: IconButton.styleFrom(
        backgroundColor: col.surfaceContainerHigh,
        foregroundColor: col.onSurface,
      ),
      onPressed: () {
        controller.action.zoomOut();
      },
      icon: Icon(Icons.zoom_out),
    );
  }
}
