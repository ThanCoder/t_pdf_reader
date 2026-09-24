import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';

import 'package:t_pdf_reader/src/reader/controllers/types/page_offset.dart';
import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';
import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:t_pdf_reader/src/reader/controllers/reader_state.dart';
import 'package:t_pdf_reader/src/reader/controllers/types/scrollbar_info.dart';
import 'package:t_pdf_reader/src/reader/cache/page_image_cache.dart';
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
  int? getCurrentPage() {
    final pages = visibleCachedPages;
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

  @override
  void scrollBy(double dy) {
    final maxOffset = max(0.0, contentHeight - state.recentViewportHeight);
    if (maxOffset <= 0) return;
    state.currentOffset = (state.currentOffset + dy).clamp(0.0, maxOffset);

    updateVisiablePages();
  }

  @override
  void updateVisiablePages() {
    final (
      visibleCachedPages,
      visiablePages,
    ) = PageOffsetUtils.calculateVisibleCachePages(
      pages: pageOffsets,
      scrollOffset: state.currentOffset,
      viewportHeight: state.recentViewportHeight,
      preloadPageCount: state.preloadPageCount,
    );

    if (!ListEquality<PageOffset>().equals(
      this.visibleCachedPages,
      visibleCachedPages,
    )) {
      this.visibleCachedPages = visibleCachedPages;
      state.visiableCachedPagesCount = visibleCachedPages.length;
    }

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

    _con.add(UpdateVisibleCachedPages());

    // visiable page index
    if (!const ListEquality<int>().equals(state.visiablePages, visiablePages)) {
      state.visiablePages = visiablePages;
      _con.add(UpdateVisiblePages());
    }
  }
}
