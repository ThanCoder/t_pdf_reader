import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfZoomListener extends StatelessWidget {
  const PdfZoomListener({super.key, required this.controller});
  final TPdfController controller;

  @override
  Widget build(BuildContext context) {
    ColorScheme col = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: controller.stream.zoomChanged,
      builder: (context, asyncSnapshot) {
        return Container(
          padding: .symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: col.surfaceContainerHigh,
            borderRadius: .circular(15),
          ),
          child: Text(
            controller.state.zoom.toStringAsFixed(2),
            style: TextStyle(color: col.onSurface, fontWeight: .w600),
          ),
        );
      },
    );
  }
}
