import 'dart:math';

import 'package:than_pdf_engine/core/models/page_size.dart';
import 'package:t_pdf_reader/src/reader/controllers/types/page_offset.dart';

class PageOffsetUtils {
  static List<PageOffset> calculatePageOffsets(
    List<PageSize> pages, {
    required double zoom,
    int spacing = 0,
  }) {
    final result = <PageOffset>[];

    double offset = 0;

    for (final page in pages) {
      final top = offset;
      final width = page.width * zoom;
      final height = page.height * zoom;
      final bottom = top + height;

      result.add(
        PageOffset(
          pageIndex: page.page,
          width: width,
          height: height,
          top: top,
          bottom: bottom,
        ),
      );

      offset = bottom + spacing;
    }

    return result;
  }

  /// cache pages + real visible page indexes
  static (List<PageOffset>, List<int>) calculateVisibleCachePages({
    required List<PageOffset> pages,
    required double scrollOffset,
    required double viewportHeight,
    required int preloadPageCount,
  }) {
    final viewportBottom = scrollOffset + viewportHeight;

    final firstVisible = findFirstVisiblePage(pages, scrollOffset);

    var lastVisible = firstVisible;

    // -----------------------------
    // Find REAL visible pages
    // -----------------------------

    for (var i = firstVisible; i < pages.length; i++) {
      final page = pages[i];

      // Page က viewport အောက်ကို ရောက်သွားပြီ
      if (page.top >= viewportBottom) {
        break;
      }

      // Page က viewport နဲ့ overlap ဖြစ်နေတယ်
      if (page.bottom > scrollOffset) {
        lastVisible = i;
      }
    }

    // -----------------------------
    // Real visible page indexes
    // -----------------------------

    final realVisible = <int>[];

    for (var i = firstVisible; i <= lastVisible; i++) {
      final page = pages[i];

      final isVisible = page.bottom > scrollOffset && page.top < viewportBottom;

      if (isVisible) {
        realVisible.add(i);
      }
    }

    // -----------------------------
    // Cache / preload range
    // -----------------------------

    final start = max(0, firstVisible - preloadPageCount);

    final end = min(pages.length, lastVisible + preloadPageCount + 1);

    final cachePages = pages.sublist(start, end);

    return (cachePages, realVisible);
  }

  /// binary search
  static int findFirstVisiblePage(List<PageOffset> pages, double viewportTop) {
    var low = 0;
    var high = pages.length - 1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final page = pages[mid];

      if (page.bottom <= viewportTop) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return low;
  }
}
