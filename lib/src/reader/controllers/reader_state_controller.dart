import 'dart:async';
import 'dart:math';

import 'package:t_pdf_reader/src/reader/controllers/types/page_offset.dart';
import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:t_pdf_reader/src/reader/controllers/reader_state.dart';
import 'package:t_pdf_reader/src/reader/controllers/types/scrollbar_info.dart';
import 'package:t_pdf_reader/src/reader/utils/page_image_cache.dart';
import 'package:t_pdf_reader/src/reader/utils/page_offset_utils.dart';

part 'reader_events.dart';
part 'interfaces/i_reader_controller.dart';
part 'interfaces/i_reader_state_controller.dart';
part 'handlers/scrollbar_handler.dart';
part 'handlers/zoom_handler.dart';
part 'handlers/mobile_handler.dart';
part 'handlers/layout_handler.dart';
part 'handlers/actions_handler.dart';

class ReaderStateController extends IReaderStateController
    with
        ScrollbarHandler,
        ZoomHandler,
        MobileHandler,
        LayoutHandler,
        ActionsHandler {
  @override
  List<PageOffset> visiblePages = [];
  @override
  List<PageSize> pages = [];
  @override
  List<PageOffset> pageOffsets = [];
  @override
  ReaderState state = .new();

  // void setConfig() {}

  @override
  void scrollBy(double dy) {
    final maxOffset = max(0.0, contentHeight - state.recentViewportHeight);
    // print(
    //   'recentViewportHeight: $recentViewportHeight - currentOffset: $currentOffset - maxOffset: $maxOffset',
    // );
    if (maxOffset <= 0) return;
    state.currentOffset = (state.currentOffset + dy).clamp(0.0, maxOffset);

    updateVisiablePages();
  }
  //**********************UI Visiable Page Changed**************************************** */

  @override
  void updateVisiablePages() {
    visiblePages = PageOffsetUtils.calculateVisiblePages(
      pages: pageOffsets,
      scrollOffset: state.currentOffset,
      viewportHeight: state.recentViewportHeight,
    );
    // current page event
    final currentPage = getCurrentPage();
    if (currentPage != null && state.page != currentPage) {
      state.page = currentPage + 1;
      _con.add(PageChanged(state.page));
    }

    // 🟢 ပြင်ရန် code
    final scrollInfo = getScrollbarInfo();
    if (scrollInfo != null) {
      if (state.scrollbarInfo == null ||
          state.scrollbarInfo!.thumbTop != scrollInfo.thumbTop ||
          state.scrollbarInfo!.thumbHeight != scrollInfo.thumbHeight) {
        state.scrollbarInfo = scrollInfo;
        _con.add(ScrollbarUiChanged());
      }
    }

    _con.add(UpdateVisiblePages());
  }

  @override
  double get contentHeight {
    if (pageOffsets.isEmpty) return 0;
    return pageOffsets.last.bottom.toDouble();
  }

  @override
  int? getCurrentPage() {
    final pages = visiblePages;
    if (pages.isEmpty) return null;

    final center = state.currentOffset + state.recentViewportHeight / 2;

    PageOffset closest = pages.first;
    var minDistance = double.infinity;

    for (final page in pages) {
      final pageCenter = (page.top + page.bottom) / 2;
      final distance = (pageCenter - center).abs();

      if (distance < minDistance) {
        minDistance = distance;
        closest = page;
      }
    }

    return closest.pageIndex;
  }

  //**********************Page Jump**************************************** */

  double getPageOffsetY(int pageIndex) {
    final index = pageOffsets.indexWhere((e) => e.pageIndex == pageIndex);
    if (index == -1) return -1;
    return pageOffsets[index].top;
  }
}
