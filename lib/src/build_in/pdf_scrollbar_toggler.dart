import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfScrollbarToggler extends StatelessWidget {
  const PdfScrollbarToggler({super.key, required this.controller});
  final TPdfController controller;

  @override
  Widget build(BuildContext context) {
    ColorScheme col = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: controller.stream.scrollbarUiChanged,
      builder: (context, asyncSnapshot) {
        return IconButton(
          style: IconButton.styleFrom(
            backgroundColor: controller.state.scrollbarEnable
                ? col.primaryContainer
                : col.surfaceContainerHighest,
            foregroundColor: col.onSurface,
          ),
          icon: Icon(
            controller.state.scrollbarEnable
                ? Icons.swap_vert
                : Icons.swap_vert_outlined,
          ),
          onPressed: () {
            controller.action.scrollbarEnable(
              !controller.state.scrollbarEnable,
            );
          },
        );
      },
    );
  }
}
