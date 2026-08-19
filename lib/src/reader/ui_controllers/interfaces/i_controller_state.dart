// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:t_pdf_reader/src/reader/controllers/types/scrollbar_info.dart';

abstract class IControllerState {
  double get currentOffset;
  double get totalOffset;

  double get viewportHeight;
  double get viewportWidth;

  bool get scrollbarDragging;

  double get zoom;
  double get maxZoom;
  double get minZoom;

  int get totalPage;
  int get page;

  ScrollbarInfo? get scrollbarInfo;

  double get scrollbarThumbHeight;
  double get scrollbarHeight;

  double get currentOffsetX;

  bool get isReady;

  ImageCacheState get imageCache;
}

class ImageCacheState {
  final int maxCount;
  final int maxSizeBytes;
  final int size;
  final int count;
  const ImageCacheState({
    required this.maxCount,
    required this.maxSizeBytes,
    required this.size,
    required this.count,
  });
}
