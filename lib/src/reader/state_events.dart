import 'package:flutter/material.dart';

sealed class StateEvent {}

class LayoutChanged extends StateEvent {
  BoxConstraints constraints;
  LayoutChanged(this.constraints);
}

class MouseScrollChanged extends StateEvent {
  final Offset scrollDelta;
  MouseScrollChanged(this.scrollDelta);
}

class MouseThumbScrollChanged extends StateEvent {
  final double scrollY;
  MouseThumbScrollChanged(this.scrollY);
}
