import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfRenderImageTypeView extends StatelessWidget {
  const PdfRenderImageTypeView({
    super.key,
    required this.controller,
    this.onTap,
  });
  final TPdfController controller;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;

    return StreamBuilder(
      stream: controller.stream.pageRenderImageTypeChanged,
      builder: (context, asyncSnapshot) {
        return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: col.surfaceContainerHigh,
            foregroundColor: col.onSurface,
          ),
          onPressed:
              onTap ??
              () {
                final type = controller.state.renderImageType;
                if (type == .jpg) {
                  controller.action.setRenderImageType(.png);
                } else if (type == .png) {
                  controller.action.setRenderImageType(.webp);
                } else if (type == .webp) {
                  controller.action.setRenderImageType(.jpg);
                }
              },
          child: Text(controller.state.renderImageType.name.toUpperCase()),
        );
      },
    );
  }
}
