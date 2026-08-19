// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/ui_controllers/interfaces/i_controller_stream.dart';
import 'package:t_pdf_reader/src/reader/utils/page_image_cache.dart';

class ControllerStream extends IControllerStream {
  final ReaderStateController _reader;
  ControllerStream(this._reader);

  late final Stream<ReaderEvent> _stream = _reader.stream;

  @override
  Stream<ReaderEvent> get all => _stream;

  @override
  Stream<ReaderReady> get ready => _stream.whereType<ReaderReady>();

  @override
  Stream<ReaderLoaded> get loaded => _stream.whereType<ReaderLoaded>();

  @override
  Stream<MobileScaleChanged> get mobileScaleChanged =>
      _stream.whereType<MobileScaleChanged>();

  @override
  Stream<MobileScaleEnd> get mobileScaleEnd =>
      _stream.whereType<MobileScaleEnd>();

  @override
  Stream<MobileScaleStart> get mobileScaleStart =>
      _stream.whereType<MobileScaleStart>();

  @override
  Stream<PageChanged> get pageChanged => _stream.whereType<PageChanged>();

  @override
  Stream<ScaleChanged> get scaleChanged => _stream.whereType<ScaleChanged>();

  @override
  Stream<ScrollEnd> get scrollEnd => _stream.whereType<ScrollEnd>();

  @override
  Stream<ScrollbarDragEvent> get scrollbarDragEvent =>
      _stream.whereType<ScrollbarDragEvent>();

  @override
  Stream<ScrollbarUiChanged> get scrollbarUiChanged =>
      _stream.whereType<ScrollbarUiChanged>();

  @override
  Stream<ReaderUILoaded> get uiLoaded => _stream.whereType<ReaderUILoaded>();

  @override
  Stream<UpdateOffset> get updateOffset => _stream.whereType<UpdateOffset>();

  @override
  Stream<UpdateViewort> get updateViewort => _stream.whereType<UpdateViewort>();

  @override
  Stream<UpdateViewortHeight> get updateViewortHeight =>
      _stream.whereType<UpdateViewortHeight>();

  @override
  Stream<UpdateViewortWidth> get updateViewortWidth =>
      _stream.whereType<UpdateViewortWidth>();

  @override
  Stream<UpdateVisiblePages> get updateVisiblePages =>
      _stream.whereType<UpdateVisiblePages>();

  @override
  Stream<ZoomChanged> get zoomChanged => _stream.whereType<ZoomChanged>();

  late final Stream<PageImageCacheEvent> _cacheStream =
      _reader.pageImageCache.stream;

  @override
  late final ImageCacheStream imageCache = .new(
    all: _cacheStream,
    put: _cacheStream.whereType<PageImageCachePut>(),
    clear: _cacheStream.whereType<PageImageCacheClear>(),
    configChanged: _cacheStream.whereType<PageImageCacheConfigChanged>(),
    remove: _cacheStream.whereType<PageImageCacheRemove>(),
  );
}
