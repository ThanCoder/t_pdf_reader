import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfVisiablePageView extends StatelessWidget {
  const PdfVisiablePageView({super.key, required this.controller});
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
          child: Text(
            'Visiable: ${controller.state.visiablePagesCount}',
            style: TextStyle(color: col.onSurface, fontWeight: .w600),
          ),
        );
      },
    );
  }
}
