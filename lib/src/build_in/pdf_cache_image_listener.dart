import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/utils.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfCacheImageListener extends StatelessWidget {
  const PdfCacheImageListener({super.key, required this.controller});
  final TPdfController controller;

  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: controller.stream.imageCache.put,
      builder: (context, asyncSnapshot) {
        return Container(
          padding: .symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            color: col.surfaceContainerHigh,
            borderRadius: .circular(15),
          ),
          child: Text(
            '${controller.state.imageCache.count}/${controller.state.imageCache.size.fileSizeLabel()}',

            style: TextStyle(color: col.onSurface, fontWeight: .w600),
          ),
        );
      },
    );
  }
}
