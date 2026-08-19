// ignore_for_file: library_private_types_in_public_api

part of '../t_pdf_reader.dart';

mixin ReaderScrollbarLogic {
  _TPdfReaderState get state;
  ReaderStateController get stateController;
  AnimationController get animationController;

  Widget buildScrollbarWidget(BoxConstraints constraints) {
    return ReaderScrollbar(
      controller: stateController,
      animationController: animationController,
    );
  }
}
