import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfReloadPageView extends StatelessWidget {
  const PdfReloadPageView({super.key, required this.controller, this.onTap});
  final TPdfController controller;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;

    return StreamBuilder(
      stream: controller.stream.preloadPageCountChanged,
      builder: (context, asyncSnapshot) {
        return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: col.surfaceContainerHigh,
            foregroundColor: col.onSurface,
          ),
          onPressed:
              onTap ??
              () {
                final count = controller.state.preloadPageCount;
                if (count == 0) {
                  controller.action.setPreloadPageCount(1);
                } else if (count == 1) {
                  controller.action.setPreloadPageCount(2);
                }
                if (count == 2) {
                  controller.action.setPreloadPageCount(3);
                }
                if (count == 3) {
                  controller.action.setPreloadPageCount(0);
                }
              },
          child: Text('Preload: ${controller.state.preloadPageCount}'),
        );
      },
    );
  }
}
