import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfThreadLabelView extends StatelessWidget {
  const PdfThreadLabelView({super.key, required this.controller});
  final TPdfController controller;

  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: controller.stream.updateVisiblePages,
      builder: (context, asyncSnapshot) {
        return Container(
          padding: .symmetric(vertical: 4, horizontal: 6),
          decoration: BoxDecoration(
            color: col.surfaceContainerHigh,
            borderRadius: .circular(15),
          ),
          child: Tooltip(
            message: 'Pdf Render Image Thread',
            child: Text(
              controller.pageImageWorkerType.label,
              style: TextStyle(color: col.onSurface, fontWeight: .w600),
            ),
          ),
        );
      },
    );
  }
}
