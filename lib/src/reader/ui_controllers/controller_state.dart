import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/controllers/types/scrollbar_info.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_state.dart';

class ControllerState extends IControllerState {
  final ReaderStateController _reader;
  ControllerState(this._reader);

  @override
  bool get scrollbarEnable => _reader.state.scrollbarEnable;

  @override
  double get currentOffset => _reader.state.currentOffset;

  @override
  double get currentOffsetX => _reader.state.currentOffsetX;

  @override
  bool get isReady => _reader.state.isReady;

  @override
  double get maxZoom => _reader.state.maxZoom;

  @override
  double get minZoom => _reader.state.minZoom;

  @override
  int get page => _reader.state.page;

  @override
  bool get scrollbarDragging => _reader.state.scrollbarDragging;

  @override
  double get scrollbarHeight => _reader.state.scrollbarHeight;

  @override
  ScrollbarInfo? get scrollbarInfo => _reader.state.scrollbarInfo;

  @override
  double get scrollbarThumbHeight => _reader.state.scrollbarThumbHeight;

  @override
  double get totalOffset => _reader.state.totalOffset;

  @override
  int get totalPage => _reader.state.totalPage;

  @override
  double get viewportHeight => _reader.state.recentViewportHeight;

  @override
  double get viewportWidth => _reader.state.recentViewportWidth;

  @override
  double get zoom => _reader.state.zoom;

  @override
  ImageCacheState get imageCache => .new(
    maxCount: _reader.pageImageCache.maxCount,
    maxSizeBytes: _reader.pageImageCache.maxSizeBytes,
    size: _reader.pageImageCache.size,
    count: _reader.pageImageCache.count,
  );

  @override
  double get zoomStep => _reader.state.zoomStep;

  @override
  double get pageScrollStep => _reader.state.pageScrollStep;
}
