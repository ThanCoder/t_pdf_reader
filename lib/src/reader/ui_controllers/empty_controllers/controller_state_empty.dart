import 'package:t_pdf_reader/src/reader/controllers/types/scrollbar_info.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_state.dart';

class ControllerStateEmpty extends IControllerState {
  @override
  bool get scrollbarEnable => false;
  @override
  double get currentOffset => 0;

  @override
  double get currentOffsetX => 0;

  @override
  ImageCacheState get imageCache =>
      .new(maxCount: 0, maxSizeBytes: 0, size: 0, count: 0);

  @override
  bool get isReady => false;

  @override
  double get maxZoom => 0;

  @override
  double get minZoom => 0;

  @override
  int get page => 0;

  @override
  bool get scrollbarDragging => false;

  @override
  double get scrollbarHeight => 0;

  @override
  ScrollbarInfo? get scrollbarInfo => null;

  @override
  double get scrollbarThumbHeight => 0;

  @override
  double get totalOffset => 0;

  @override
  int get totalPage => 0;

  @override
  double get viewportHeight => 0;

  @override
  double get viewportWidth => 0;

  @override
  double get zoom => 0;

  @override
  double get zoomStep => 0;

  @override
  double get pageScrollStep => 0;
}
