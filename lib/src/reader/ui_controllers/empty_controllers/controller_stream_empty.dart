import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_stream.dart';

class ControllerStreamEmpty extends IControllerStream {
  @override
  Stream<ReaderEvent> get all => .empty();

  @override
  Stream<ReaderLoaded> get loaded => .empty();

  @override
  Stream<MobileScaleChanged> get mobileScaleChanged => .empty();

  @override
  Stream<MobileScaleEnd> get mobileScaleEnd => .empty();

  @override
  Stream<MobileScaleStart> get mobileScaleStart => .empty();

  @override
  Stream<PageChanged> get pageChanged => .empty();

  @override
  Stream<ReaderReady> get ready => .empty();

  @override
  Stream<ScaleChanged> get scaleChanged => .empty();

  @override
  Stream<ScrollEnd> get scrollEnd => .empty();

  @override
  Stream<ScrollbarDragEvent> get scrollbarDragEvent => .empty();

  @override
  Stream<ScrollbarUiChanged> get scrollbarUiChanged => .empty();

  @override
  Stream<ReaderUILoaded> get uiLoaded => .empty();

  @override
  Stream<UpdateOffset> get updateOffset => .empty();

  @override
  Stream<UpdateViewort> get updateViewort => .empty();

  @override
  Stream<UpdateViewortHeight> get updateViewortHeight => .empty();

  @override
  Stream<UpdateViewortWidth> get updateViewortWidth => .empty();

  @override
  Stream<UpdateVisiblePages> get updateVisiblePages => .empty();

  @override
  Stream<ZoomChanged> get zoomChanged => .empty();

  @override
  ImageCacheStream get imageCache => .new(
    all: .empty(),
    put: .empty(),
    clear: .empty(),
    configChanged: .empty(),
    remove: .empty(),
  );
}
