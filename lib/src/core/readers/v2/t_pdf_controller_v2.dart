part of 't_pdf_reader_v2_base.dart';

class TPdfControllerV2 extends ChangeNotifier {
  // Internal State (Reader ဘက်ကနေ လာပြီး အပ်ဒိတ်လုပ်မယ့် တန်ဖိုးများ)
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  double _minScale = 1.0;
  double _maxScale = 4.0;
  bool _scaleEnabled = false;
  bool _panEnabled = false;
  PanAxis _panAxis = PanAxis.free;
  double _currentZoom = 1.0;

  TPdfControllerV2({
    this._currentPage = 0,
    this._minScale = 0.3,
    this._maxScale = 4.0,
    this._scaleEnabled = false,
    this._panAxis = PanAxis.free,
    this._panEnabled = false,
    this._currentZoom = 1.0,
  });

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isReady => _isReady;
  double get minScale => _minScale;
  double get maxScale => _maxScale;
  bool get scaleEnabled => _scaleEnabled;
  bool get panEnabled => _panEnabled;
  PanAxis get panAxis => _panAxis;
  double get currentZoom => _currentZoom;

  // *****************Event ********************
  @protected
  final StreamController<UserEvent> _userEventStreamController =
      StreamController<UserEvent>.broadcast();
  final StreamController<PdfReaderEvent> _pdfReaderEventStreamController =
      StreamController<PdfReaderEvent>.broadcast();

  /// listen pdf reader
  Stream<UserEvent> get _userEvent => _userEventStreamController.stream;
  Stream<PdfReaderEvent> get pdfReaderEvent =>
      _pdfReaderEventStreamController.stream;

  void _attachReader({
    required Duration loadedElapsedTime,
    required int totalPage,
  }) {
    _totalPages = totalPage;
    _isReady = true;
    notifyListeners();
    // _onLoadedPdfCallback?.call(_totalPages, loadedElapsedTime);
    if (!_pdfReaderEventStreamController.isClosed) {
      _pdfReaderEventStreamController.add(
        PdfOnLoaded(totalPage: totalPage, loadedElapsedTime: loadedElapsedTime),
      );
    }
  }

  void _detachReader() {
    _isReady = false;
    _userEventStreamController.close();
    _pdfReaderEventStreamController.close();
  }

  Stream<PdfOnLoaded> get onLoaded =>
      pdfReaderEvent.where((e) => e is PdfOnLoaded).cast<PdfOnLoaded>();

  Stream<PdfScreenSizeChanged> get onSizedChanged => pdfReaderEvent
      .where((e) => e is PdfScreenSizeChanged)
      .cast<PdfScreenSizeChanged>();
  Stream<PdfPageChanged> get onPageChanged =>
      pdfReaderEvent.where((e) => e is PdfPageChanged).cast<PdfPageChanged>();

  Stream<PdfZoomChanged> get onZoomChanged =>
      pdfReaderEvent.where((e) => e is PdfZoomChanged).cast<PdfZoomChanged>();

  void _notifyListeners() {
    notifyListeners();
  }

  void jumpToPage(int page) =>
      _userEventStreamController.add(UserJumpToPage(page));

  /// 1x မှ 4x အတွင်းပဲ ပေးမယ်
  void setZoom(double zoomLevel) {
    final clampedZoom = zoomLevel.clamp(minScale, maxScale);
    if (clampedZoom == _currentZoom) return;
    if (!_userEventStreamController.isClosed) {
      _userEventStreamController.add(UserZoom(clampedZoom));
    }
  }

  void setScaleEnabled(bool enable) {
    _scaleEnabled = enable;
    notifyListeners();
  }

  void setPanEnabled(bool enable) {
    _panEnabled = enable;
    notifyListeners();
  }

  void setPanAxis(PanAxis axis) {
    _panAxis = axis;
    notifyListeners();
  }

  void setMinScale(double scale) {
    _minScale = scale;
    notifyListeners();
  }

  void setMaxScale(double scale) {
    _maxScale = scale;
    notifyListeners();
  }
}
