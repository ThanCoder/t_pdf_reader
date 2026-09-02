import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/utils.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfCacheImageListener extends StatefulWidget {
  const PdfCacheImageListener({
    super.key,
    required this.controller,
    this.onTap,
  });
  final TPdfController controller;
  final void Function()? onTap;

  @override
  State<PdfCacheImageListener> createState() => _PdfCacheImageListenerState();
}

class _PdfCacheImageListenerState extends State<PdfCacheImageListener> {
  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: widget.controller.stream.imageCache.all,
      builder: (context, asyncSnapshot) {
        return InkWell(
          onTap: widget.onTap ?? showClearCacheDialog,
          child: Container(
            padding: .symmetric(vertical: 6, horizontal: 8),
            decoration: BoxDecoration(
              color: col.surfaceContainerHigh,
              borderRadius: .circular(15),
            ),
            child: Text(
              '${widget.controller.state.imageCache.count}/${widget.controller.state.imageCache.size.fileSizeLabel()}',

              style: TextStyle(color: col.onSurface, fontWeight: .w600),
            ),
          ),
        );
      },
    );
  }

  void showClearCacheDialog() {
    final col = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        content: Text('Want to Delete Cache!'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: col.surfaceContainer,
              foregroundColor: col.onSurface,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: col.errorContainer,
              foregroundColor: col.onErrorContainer,
            ),
            onPressed: () {
              Navigator.pop(context);
              widget.controller.action.clearImageCache();
            },
            child: Text('Clear Cache'),
          ),
        ],
      ),
    );
  }
}
