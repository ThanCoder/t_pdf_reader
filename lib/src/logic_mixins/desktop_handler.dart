import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:t_pdf_reader/src/events/state_events.dart';
import 'package:t_pdf_reader/src/state/reader_state.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';


mixin DesktopHandler {
  BuildContext get context;
  ReaderState get state;
  ReaderStateController get stateController;
  Widget mobileHandler(BoxConstraints constraints);

  Widget desktopListener(BoxConstraints constraints) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          stateController.dispatch(MouseScrollChanged(event.scrollDelta));
        }
      },
      child: mobileHandler(constraints),
    );
  }
}
