part of '../../t_pdf_reader.dart';

/// Represents a lifecycle event emitted when a PDF controller's attachment
/// state changes.
sealed class ControllerLifecycleEvent {
  /// Creates a lifecycle event.
  const ControllerLifecycleEvent();
}

/// Indicates that the controller has been attached to a reader.
class ControllerAttached extends ControllerLifecycleEvent {
  /// Creates an event indicating that the controller has been attached.
  const ControllerAttached();
}

/// Indicates that the controller has been detached from a reader.
class ControllerDetached extends ControllerLifecycleEvent {
  /// Creates an event indicating that the controller has been detached.
  const ControllerDetached();
}

/// Defines the base interface and lifecycle management for a PDF reader controller.
///
/// Provides access to the reader's state, actions, and event streams.
/// A controller can be attached to a [ReaderStateController] to interact with
/// an active reader and observe its lifecycle events.
sealed class ITPdfController {
  /// Broadcast controller for lifecycle events.
  ///
  /// Allows multiple listeners to observe attachment and detachment events.
  final _con = StreamController<ControllerLifecycleEvent>.broadcast();

  /// Emits lifecycle events whenever the controller's attachment state changes.
  Stream<ControllerLifecycleEvent> get lifecycle => _con.stream;

  /// Emits events when the controller is attached to a reader.
  ///
  /// Detachment events and other lifecycle events are excluded.
  Stream<ControllerAttached> get attached => lifecycle
      .where((e) => e is ControllerAttached)
      .cast<ControllerAttached>();

  /// Releases the controller's lifecycle event stream resources.
  ///
  /// After disposal, no further lifecycle events should be emitted.
  void dispose() {
    _con.close();
  }

  /// Provides access to the current reader state.
  ///
  /// Uses an empty state implementation until a reader is attached.
  IControllerState state = ControllerStateEmpty();

  /// Provides actions for controlling the reader.
  ///
  /// Uses an empty action implementation until a reader is attached.
  IControllerAction action = ControllerActionEmpty();

  /// Provides access to the reader's event streams.
  ///
  /// Uses empty streams until a reader is attached.
  IControllerStream stream = ControllerStreamEmpty();

  /// The reader currently attached to this controller, if any.
  ReaderStateController? _reader;

  /// Attaches this controller to the specified reader.
  ///
  /// Does nothing if a reader is already attached.
  /// Initializes the state, action, and stream interfaces for the reader,
  /// then emits a [ControllerAttached] event.
  void _attach(ReaderStateController reader) {
    // assert(_reader == null, 'Controller is already attached.');
    if (_reader != null) return;
    _reader = reader;

    state = ControllerState(reader);
    action = ControllerActions(reader);
    stream = ControllerStream(reader);

    _con.add(ControllerAttached());
  }

  /// Detaches this controller from the specified reader.
  ///
  /// Does nothing if the specified reader is not the currently attached reader.
  /// Clears the reader reference and emits a [ControllerDetached] event.
  void _detach(ReaderStateController reader) {
    if (!identical(_reader, reader)) return;
    _reader = null;
    _con.add(ControllerDetached());
  }
}
