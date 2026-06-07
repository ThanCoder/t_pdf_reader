import 'dart:async';

import 'package:flutter/material.dart';

typedef JumpToPageCallback = void Function(int page);
typedef OnLoadedPdfCallback =
    void Function(int totalPage, Duration loadedElapsedTime);
typedef ZoomToPageCallback = void Function(double zoom);

class TPdfController extends ChangeNotifier {
  // Internal State (Reader ဘက်ကနေ လာပြီး အပ်ဒိတ်လုပ်မယ့် တန်ဖိုးများ)
  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  double _minScale = 1.0;
  double _maxScale = 4.0;
  bool _scaleEnabled = false;
  bool _panEnabled = false;
  PanAxis _panAxis = PanAxis.free;

  TPdfController({
    this._currentPage = 0,
    this._minScale = 1.0,
    this._maxScale = 4.0,
    this._scaleEnabled = false,
    this._panAxis = PanAxis.free,
    this._panEnabled = false,
  });

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get isReady => _isReady;
  double get minScale => _minScale;
  double get maxScale => _maxScale;
  bool get scaleEnabled => _scaleEnabled;
  bool get panEnabled => _panEnabled;
  PanAxis get panAxis => _panAxis;

  // Reader ရဲ့ State ကို လှမ်းကိုင်မယ့် Dynamic ခေါ်ဆိုမှုများ (Private)
  JumpToPageCallback? _jumpToPageClosure;
  OnLoadedPdfCallback? _onLoadedPdfCallback;
  ZoomToPageCallback? _zoomToPageCallback;

  void attachReader({
    required Duration loadedElapsedTime,
    required int totalPage,
    required JumpToPageCallback jumpToPageClosure,
    required ZoomToPageCallback zoomToPageCallback,
  }) {
    _totalPages = totalPage;
    _jumpToPageClosure = jumpToPageClosure;
    _zoomToPageCallback = zoomToPageCallback;
    _isReady = true;
    notifyListeners();
    _onLoadedPdfCallback?.call(_totalPages, loadedElapsedTime);
  }

  void detachReader() {
    _isReady = false;
    _jumpToPageClosure = null;
    _zoomToPageCallback = null;
  }

  void onLoaded(OnLoadedPdfCallback onLoadedCallback) {
    _onLoadedPdfCallback = onLoadedCallback;
  }

  void updateCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      notifyListeners();
    }
  }

  void jumpToPage(int page) {
    _jumpToPageClosure?.call(page);
  }

  // ******* low image cache ********
  /// (total,loaded)
  final lowImageProgressStream = StreamController<(int, int)>.broadcast();

  // ******* zoom ********

  TransformationController? _transformationController;
  // 🛠️ Reader ဘက်ကနေ TransformationController ကို လာအပ်မည့် Function
  void attachTransformationController(TransformationController controller) {
    _transformationController = controller;
    // InteractiveViewer ဘက်က လက်နဲ့ချဲ့ရင်လည်း လက်ရှိ zoom တန်ဖိုးကို သိနေအောင် listener စိုက်မယ်
    _transformationController!.addListener(_onMatrixChanged);
  }

  void detachTransformationController() {
    _transformationController?.removeListener(_onMatrixChanged);
    _transformationController = null;
  }

  // 🔍 လက်ရှိ Zoom Level ကို အပြင်က လှမ်းတောင်းရင် ပေးမည့် Getter (getZoom အစားသုံးရန်)
  double get currentZoom {
    if (_transformationController == null) return 1.0;
    // Matrix4 ရဲ့ row 0, column 0 တန်ဖိုးဟာ Scale (Zoom) တန်ဖိုး ဖြစ်ပါတယ်
    return _transformationController!.value.row0.r;
  }

  void setZoom(double zoomLevel) {
    if (_transformationController == null) return;

    final clampedZoom = zoomLevel.clamp(
      minScale,
      maxScale,
    ); // 1x မှ 4x အတွင်းပဲ ပေးမယ်

    _zoomToPageCallback?.call(clampedZoom);

    notifyListeners(); // UI တွေကို သတင်းပို့မယ်
  }

  void _onMatrixChanged() {
    notifyListeners(); // လက်နှစ်ချောင်းနဲ့ ကားချဲ့လိုက်ရင်လည်း UI Screen တွေ သိအောင် အော်ပေးမယ်
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

  @override
  void dispose() {
    detachTransformationController();
    detachReader();
    lowImageProgressStream.close();
    super.dispose();
  }

  // ***************Cache ****************
}
