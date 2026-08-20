import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfPageListener extends StatelessWidget {
  const PdfPageListener({super.key, required this.controller, this.onClicked});
  final TPdfController controller;
  final VoidCallback? onClicked;

  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: controller.stream.pageChanged,
      builder: (context, asyncSnapshot) {
        return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: col.surfaceContainerHigh,
            foregroundColor: col.onSurface,
          ),
          onPressed: onClicked,
          child: Text(
            '${controller.state.page}/${controller.state.totalPage}',
            style: TextStyle(color: col.onSurface, fontWeight: .w600),
          ),
        );
      },
    );
  }
}
