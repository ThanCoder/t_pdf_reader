import 'dart:async';

import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/default_widgets/scrollbar_widgets.dart';
import 'package:t_pdf_reader/src/events/pdf_events.dart';
import 'package:t_pdf_reader/src/events/user_events.dart';
import 'package:t_pdf_reader/src/logic_mixins/desktop_handler.dart';
import 'package:t_pdf_reader/src/logic_mixins/mobile_handler.dart';
import 'package:t_pdf_reader/src/logic_mixins/page_list_handler.dart';
import 'package:t_pdf_reader/src/reader/reader_layout_engine.dart';
import 'package:t_pdf_reader/src/state/reader_state.dart';
import 'package:t_pdf_reader/src/events/state_events.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';

part 't_pdf_controller.dart';
part 'reader/t_reader.dart';
part 'state/reader_state_controller.dart';
part 'logic_mixins/scrollbar_handler.dart';

class TPdfReader extends StatefulWidget {
  final String path;
  final String? password;
  final TPdfController controller;
  const TPdfReader({
    super.key,
    required this.path,
    this.password,
    required this.controller,
  });

  @override
  State<TPdfReader> createState() => _TPdfReaderState();
}

class _TPdfReaderState extends State<TPdfReader> {
  @override
  void initState() {
    init();
    super.initState();
  }

  @override
  void dispose() {
    pdfWorker.dispose();
    super.dispose();
  }

  final pdfWorker = PdfBackgroundWorker.getInstance;
  List<PageSize> pageSizes = [];
  bool isLoading = false;

  void init() async {
    try {
      setState(() {
        isLoading = true;
      });
      pageSizes = await PdfCore.getAllPageSizedList(widget.path);
      await pdfWorker.run(widget.path);
      // await pdfWorker.requestPageImageJpg(pageIndex, width: width, height: height)
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('[TPdfReader:init]: $e');
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (widget.controller.progressWidget != null) {
        return Center(child: widget.controller.progressWidget!(context));
      }
      return Center(child: CircularProgressIndicator.adaptive());
    }
    return TReader(
      pageSizes: pageSizes,
      pdfWorker: pdfWorker,
      controller: widget.controller,
    );
  }
}
