part of '../reader_state_controller.dart';

sealed class IReaderStateController {
  ReaderState get state;
  double get contentHeight;
  List<PageOffset> get pageOffsets;
  List<PageOffset> get visiblePages;
  List<PageSize> get pages;
  void scrollBy(double dy);

  set pageOffsets(List<PageOffset> val);
  set visiblePages(List<PageOffset> val);
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
}
