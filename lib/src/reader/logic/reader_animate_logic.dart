// ignore_for_file: unused_element, library_private_types_in_public_api

part of '../t_pdf_reader.dart';

mixin ReaderAnimateLogic {
  _TPdfReaderState get state;
  ReaderStateController get stateController;
  AnimationController get animationController;

  void initReaderAnimation() {
    animationController.addListener(() {
      final offset = animationController.value;

      stateController.setOffset(offset);
    });
    animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        stateController.addEvent(ScrollEnd());
      }
    });

    // stateController.stream.whereType<ReaderUILoaded>().listen((event) {
    //   stateController.setZoom(stateController.fitWidthZoom);
    // });
  }

  void fling(double velocity) {
    animationController.value = stateController.state.currentOffset;

    final simulation = FrictionSimulation(
      0.135,
      stateController.state.currentOffset,
      velocity,
    );

    animationController.animateWith(simulation);
  }
}
