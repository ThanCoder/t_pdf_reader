part of '../../t_pdf_reader.dart';

sealed class ControllerLifecycleEvent {
  const ControllerLifecycleEvent();
}

class ControllerAttached extends ControllerLifecycleEvent {
  const ControllerAttached();
}

class ControllerDetached extends ControllerLifecycleEvent {
  const ControllerDetached();
}

sealed class ITPdfController {
  final _con = StreamController<ControllerLifecycleEvent>.broadcast();
  Stream<ControllerLifecycleEvent> get lifecycle => _con.stream;
  Stream<ControllerAttached> get attached => lifecycle
      .where((e) => e is ControllerAttached)
      .cast<ControllerAttached>();

  void dispose() {
    _con.close();
  }

  IControllerState state = ControllerStateEmpty();
  IControllerAction action = ControllerActionEmpty();
  IControllerStream stream = ControllerStreamEmpty();

  ReaderStateController? _reader;

  void _attach(ReaderStateController reader) {
    // assert(_reader == null, 'Controller is already attached.');
    if (_reader != null) return;
    _reader = reader;

    state = ControllerState(reader);
    action = ControllerActions(reader);
    stream = ControllerStream(reader);

    _con.add(ControllerAttached());
  }

  void _detach(ReaderStateController reader) {
    if (!identical(_reader, reader)) return;
    _reader = null;
    _con.add(ControllerDetached());
  }
}
