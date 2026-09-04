part of '../reader_state_controller.dart';

sealed class IReaderStateController {
  List<PageOffset> visibleCachedPages = [];
  List<PageSize> pages = [];
  List<PageOffset> pageOffsets = [];
  ReaderState state = .new();

  double get contentHeight {
    if (pageOffsets.isEmpty) return 0;
    return pageOffsets.last.bottom.toDouble();
  }

  void scrollBy(double dy);

  void updateVisiablePages();
  int? getCurrentPage();

  // stream
  final _con = StreamController<ReaderEvent>.broadcast();
  Stream<ReaderEvent> get stream => _con.stream;

  final PageImageCache pageImageCache = PageImageCache();
  void addEvent(ReaderEvent event) {
    _con.add(event);
  }

  void dipose() {
    _con.close();
  }

  double getPageOffsetY(int pageIndex) {
    final index = pageOffsets.indexWhere((e) => e.pageIndex == pageIndex);
    if (index == -1) return -1;
    return pageOffsets[index].top;
  }
}
