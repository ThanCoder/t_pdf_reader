import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/controller_stream.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/empty_controllers/controller_stream_empty.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_stream.dart';
import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';

import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/ui/reader_item.dart';
import 'package:t_pdf_reader/src/reader/ui/reader_scrollbar.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/controller_action.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/controller_state.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/empty_controllers/controller_action_empty.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/empty_controllers/controller_state_empty.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_action.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_state.dart';
import 'package:t_pdf_reader/src/reader/utils/page_offset_utils.dart';

part 'logic/reader_animate_logic.dart';
part 'logic/reader_init_mixin.dart';
part 'logic/reader_pdf_list_logic.dart';
part 'logic/reader_scrollbar_logic.dart';
part 'logic/reader_ui_event_listener_logic.dart';
part 'ui_controllers/t_pdf_controller.dart';

class TPdfReader extends StatefulWidget {
  const TPdfReader({
    super.key,
    required this.path,
    this.password,
    required this.controller,
  });

  final String path;
  final String? password;
  final TPdfController controller;

  @override
  State<TPdfReader> createState() => _TPdfReaderState();
}

class _TPdfReaderState extends State<TPdfReader>
    with
        ReaderInitMixin,
        SingleTickerProviderStateMixin,
        ReaderAnimateLogic,
        ReaderUiEventListenerLogic,
        ReaderScrollbarLogic,
        ReaderPdfListLogic {
  @override
  _TPdfReaderState get state => this;

  @override
  final worker = PdfReaderWorker();

  @override
  TPdfController get controller => widget.controller;

  @override
  final ReaderStateController stateController = ReaderStateController();

  void updateState() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  late final AnimationController animationController;
  @override
  void initState() {
    // attach TController
    widget.controller._attach(stateController);
    animationController = AnimationController.unbounded(vsync: this);
    initReaderAnimation();
    super.initState();
    onReaderInit();
  }

  @override
  void onReaderLoaded() {
    stateController.state.isReady = true;
    stateController.addEvent(ReaderReady());
  }

  @override
  void dispose() {
    animationController.dispose();
    stateController.dipose();
    worker.close();
    widget.controller._detach(stateController);
    super.dispose();
  }

  String? error;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator.adaptive());
    }
    if (error != null) {
      return Center(
        child: Text(error!, style: TextStyle(color: Colors.red)),
      );
    }
    return _viewer;
  }

  Widget get _viewer {
    return listenAllUiEvent(
      childBuilder: (constraints) {
        return Stack(
          children: [
            buildPdfListWidget(constraints),
            buildScrollbarWidget(constraints),
            // testHeaderWidget(),
          ],
        );
      },
    );
  }
}
