import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_pdf_reader/src/core/low_levels/backgrounds/pdf_background_document.dart';
import 'package:t_pdf_reader/src/core/low_levels/classes/types.dart';
import 'package:t_pdf_reader/src/core/readers/v3/default_ui/default_pdf_ui_util.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

part 't_pdf_controller_v3.dart';
part 't_custom_pdf_viewer.dart';
part 'default_ui/custom_widgets.dart';
part 'logic_mixins/viewer_layout_mixin.dart';
part 'logic_mixins/viewer_cache_mixin.dart';
part 'logic_mixins/viewer_scroll_animation_mixin.dart';
part 'logic_mixins/touch_zoom_handler_mixin.dart';
part 'logic_mixins/scroll_keyboard_handler_mixin.dart';
part 'logic_mixins/viewer_page_build_handler.dart';
part 'logic_mixins/scrollbar_handler.dart';

class TPdfReaderV3 extends StatefulWidget {
  final String source;
  final String? password;
  final TPdfControllerV3 controller;
  const TPdfReaderV3({
    super.key,
    required this.source,
    this.password,
    required this.controller,
  });

  @override
  State<TPdfReaderV3> createState() => _TPdfReaderV3State();
}

class _TPdfReaderV3State extends State<TPdfReaderV3> {
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    document.close();
    widget.controller._detachReader();
    super.dispose();
  }

  bool isLoading = false;
  String? error;
  List<PdfSizedPage> sizedPages = [];
  PdfBackgroundDocument document = PdfBackgroundDocument();

  Future<void> init() async {
    try {
      widget.controller._stopWatch.start();

      setState(() {
        isLoading = true;
        error = null;
      });

      await document.openFile(widget.source, password: widget.password);

      sizedPages = await document.getSizedPage();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.controller._attachReader(totalPage: sizedPages.length);
      });

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      error = e.toString();
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      if (widget.controller._customLoader != null) {
        return widget.controller._customLoader!(context);
      }
      return Center(child: CircularProgressIndicator.adaptive());
    }
    if (error != null) {
      if (widget.controller._customError != null) {
        return widget.controller._customError!(context, error!);
      }
      return Center(
        child: Text(error!, style: TextStyle(color: Colors.red)),
      );
    }
    // return _listView;
    return TCustomPdfViewer(
      sizedPages: sizedPages,
      controller: widget.controller,
      document: document,
    );
  }
}
