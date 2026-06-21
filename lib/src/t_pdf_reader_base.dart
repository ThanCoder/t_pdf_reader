// ignore_for_file: avoid_print, public_member_api_docs, sort_constructors_first
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/reader/page_offset.dart';
import 'package:t_pdf_reader/src/reader/reader_state.dart';
import 'package:t_pdf_reader/src/reader/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/state_events.dart';
import 'package:than_pdf_engine/than_pdf_engine.dart';

part 't_pdf_controller.dart';
part 'reader/t_reader.dart';

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

  final pdfWorker = PdfBackgroundWorker.instance;
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
      print(e);
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    return TReader(
      pageSizes: pageSizes,
      pdfWorker: pdfWorker,
      controller: widget.controller,
    );
  }
}
