import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_action.dart';

class ControllerActionEmpty extends IControllerAction {
  Never _notAttached() {
    throw StateError('TPdfController is not attached to a TPdfReader.');
  }

  @override
  void setZoomStep(double step) {
    _notAttached();
  }

  @override
  void jumpPage(int page) {
    _notAttached();
  }

  @override
  void setMaxZoom(double maxZoom) {
    _notAttached();
  }

  @override
  void setMinZoom(double minZoom) {
    _notAttached();
  }

  @override
  void setOffset(double offsetY) {
    _notAttached();
  }

  @override
  void setOffsetX(double offsetX) {
    _notAttached();
  }

  @override
  void setPageImageCache({
    int maxCount = 200,
    int maxSizeBytes = 10 * 1024 * 1024,
  }) {
    _notAttached();
  }

  @override
  void setScrollbarHeight(double height) {
    _notAttached();
  }

  @override
  void setZoom(double value) {
    _notAttached();
  }

  @override
  void setZoomSensitivity(double zoomSensitivity) {
    _notAttached();
  }

  @override
  void setFitZoom() {
    _notAttached();
  }

  @override
  void zoomIn() {
    _notAttached();
  }

  @override
  void zoomOut() {
    _notAttached();
  }
}
