import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfPreloadPageView extends StatefulWidget {
  const PdfPreloadPageView({
    super.key,
    required this.controller,
    this.showCountLen = 21,
  });
  final TPdfController controller;
  final int showCountLen;

  @override
  State<PdfPreloadPageView> createState() => _PdfPreloadPageViewState();
}

class _PdfPreloadPageViewState extends State<PdfPreloadPageView> {
  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;
    return StreamBuilder(
      stream: widget.controller.stream.preloadPageCountChanged,
      builder: (context, asyncSnapshot) {
        return TextButton(
          style: TextButton.styleFrom(
            backgroundColor: col.surfaceContainerHigh,
            foregroundColor: col.onSurface,
          ),
          onPressed: chooseDialog,
          child: Text('Preload: ${widget.controller.state.preloadPageCount}'),
        );
      },
    );
  }

  void chooseDialog() async {
    final pageCount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PreloadChooserDialog(
        controller: widget.controller,
        showCountLen: widget.showCountLen,
      ),
    );
    if (pageCount == null) return;
    widget.controller.action.setPreloadPageCount(pageCount);
  }
}

class _PreloadChooserDialog extends StatefulWidget {
  const new({required this.controller, this.showCountLen = 21});
  final TPdfController controller;
  final int showCountLen;

  @override
  State<_PreloadChooserDialog> createState() => _PreloadChooserDialogState();
}

class _PreloadChooserDialogState extends State<_PreloadChooserDialog> {
  @override
  void initState() {
    current = widget.controller.state.preloadPageCount;
    super.initState();
  }

  late int current;
  @override
  Widget build(BuildContext context) {
    final col = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop<int>(context, current);
      },
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                'Preload Page Count',
                textAlign: .start,
                style: TextStyle(
                  color: col.onSurface,
                  fontWeight: .w700,
                  fontSize: 18,
                ),
              ),
              SizedBox(height: 10),
              Wrap(
                spacing: 4,
                runSpacing: 3,
                children: List.generate(
                  widget.showCountLen,
                  (index) => FilledButton(
                    style: current == index
                        ? null
                        : FilledButton.styleFrom(
                            backgroundColor: col.surfaceContainer,
                            foregroundColor: col.onSurfaceVariant,
                          ),
                    onPressed: () {
                      setState(() {
                        current = index;
                      });
                    },
                    child: Text('$index'),
                  ),
                ),
              ),
              SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
