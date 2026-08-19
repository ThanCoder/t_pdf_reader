import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_action.dart';

class ControllerActions extends IControllerAction {
  final ReaderStateController _reader;
  ControllerActions(this._reader);

  @override
  void jumpPage(int page) {
    _reader.jumpPage(page);
  }

  @override
  void setScrollbarHeight(double height) {
    _reader.setScrollbarHeight(height);
  }

  @override
  void setZoom(double value) {
    _reader.setZoom(value);
  }

  @override
  void setOffset(double offsetY) {
    _reader.setOffset(offsetY);
  }

  @override
  void setOffsetX(double offsetX) {
    _reader.setOffsetX(offsetX);
  }

  @override
  void setMaxZoom(double maxZoom) {
    _reader.setMaxZoom(maxZoom);
  }

  @override
  void setMinZoom(double minZoom) {
    _reader.setMinZoom(minZoom);
  }

  @override
  void setPageImageCache({
    int maxCount = 200,
    int maxSizeBytes = 10 * 1024 * 1024,
  }) {
    _reader.setPageImageCache(maxCount: maxCount, maxSizeBytes: maxSizeBytes);
  }

  @override
  void setZoomSensitivity(double zoomSensitivity) {
    _reader.setZoomSensitivity(zoomSensitivity);
  }

  @override
  void setFitZoom() {
    _reader.setFitZoom();
  }

  @override
  void setZoomStep(double step) {
    _reader.setZoomStep(step);
  }

  @override
  void zoomIn() {
    _reader.zoomIn();
  }

  @override
  void zoomOut() {
    _reader.zoomOut();
  }
}
