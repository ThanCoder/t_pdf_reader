import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class PdfPageJumpDialog extends StatefulWidget {
  const PdfPageJumpDialog({super.key, required this.controller});

  final TPdfController controller;

  @override
  State<PdfPageJumpDialog> createState() => _PdfPageJumpDialogState();
}

class _PdfPageJumpDialogState extends State<PdfPageJumpDialog> {
  @override
  void initState() {
    textCon.text = widget.controller.state.page.toString();
    super.initState();
    focusNode.requestFocus();
  }

  @override
  void dispose() {
    textCon.dispose();
    focusNode.dispose();
    super.dispose();
  }

  final focusNode = FocusNode();
  final textCon = TextEditingController();
  String? errorText;
  ColorScheme get col => Theme.of(context).colorScheme;

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: Text(
        'Jump Page',
        style: TextStyle(fontSize: 16, fontWeight: .w600, color: col.onSurface),
      ),
      scrollable: true,
      backgroundColor: col.surfaceBright,
      content: Column(
        spacing: 4,
        crossAxisAlignment: .start,
        children: [
          Text(
            'Range: 1-${widget.controller.state.totalPage}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: .w400,
              color: col.onSurfaceVariant,
            ),
          ),
          TextField(
            maxLines: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            canRequestFocus: true,
            keyboardType: .number,
            controller: textCon,
            focusNode: focusNode,
            decoration: InputDecoration(
              errorText: errorText,
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (value) => jumpPage(),
            onChanged: onChanged,
          ),
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: col.surfaceContainerHigh,
            foregroundColor: col.onSurfaceVariant,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Close'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: col.primaryContainer,
            foregroundColor: col.onPrimaryContainer,
          ),
          onPressed: errorText != null ? null : jumpPage,
          child: Text('Jump'),
        ),
      ],
    );
  }

  void onChanged(String value) {
    if (value.isEmpty) {
      setState(() {
        errorText = 'text is empty!';
      });
      return;
    }
    final res = int.tryParse(value);
    if (res == null) {
      setState(() {
        errorText = 'text is not number!';
      });
      return;
    }
    if (res == 0) {
      setState(() {
        errorText = 'page: 1-${widget.controller.state.totalPage}';
      });
      return;
    }
    if (widget.controller.state.page == res) {
      setState(() {
        errorText = 'current page!';
      });
      return;
    }
    if (res > widget.controller.state.totalPage) {
      setState(() {
        errorText = 'page: 1-${widget.controller.state.totalPage}';
      });
      return;
    }
    setState(() {
      errorText = null;
    });
  }

  void jumpPage() {
    Navigator.pop(context);
    final next = int.parse(textCon.text);
    if (widget.controller.state.page == next) return;
    widget.controller.action.jumpPage(next);
  }
}
