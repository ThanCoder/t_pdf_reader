import 'dart:async';
import 'dart:typed_data';

import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';

class PageImageCacheItem {
  final Uint8List data;
  final double width;
  final double height;
  final int quality;
  final PageRenderImageType imageType;

  const PageImageCacheItem({
    required this.data,
    required this.width,
    required this.height,
    required this.quality,
    required this.imageType,
  });
}

sealed class PageImageCacheEvent {
  const PageImageCacheEvent();
}

class PageImageCachePut extends PageImageCacheEvent {
  const PageImageCachePut();
}

class PageImageCacheClear extends PageImageCacheEvent {
  const PageImageCacheClear();
}

class PageImageCacheConfigChanged extends PageImageCacheEvent {
  const PageImageCacheConfigChanged();
}

class PageImageCacheRemove extends PageImageCacheEvent {
  final int pageIndex;

  const PageImageCacheRemove(this.pageIndex);
}

extension ImageCacheStreamExt on Stream<PageImageCacheEvent> {
  Stream<T> whereType<T extends PageImageCacheEvent>() {
    return where((event) => event is T).cast<T>();
  }
}

class PageImageCache {
  PageImageCache({this.maxCount = 200, this.maxSizeBytes = 10 * 1024 * 1024});

  int maxCount;
  int maxSizeBytes;

  final _cache = <int, PageImageCacheItem>{};

  final _con = StreamController<PageImageCacheEvent>.broadcast();

  Stream<PageImageCacheEvent> get stream => _con.stream;

  int get count => _cache.length;

  int get size {
    return _cache.values.fold(0, (total, item) => total + item.data.length);
  }

  void setConfig(int maxCount, int maxSizeBytes) {
    this.maxCount = maxCount;
    this.maxSizeBytes = maxSizeBytes;

    _evict();

    _con.add(const PageImageCacheConfigChanged());
  }

  bool contains(
    int page, {
    required double width,
    required double height,
    required int quality,
    required PageRenderImageType imageType,
  }) {
    final item = _cache[page];

    if (item == null) {
      return false;
    }

    return item.width == width &&
        item.height == height &&
        item.quality == quality &&
        item.imageType == imageType;
  }

  void put(
    int page,
    Uint8List data, {
    required double width,
    required double height,
    required int quality,
    required PageRenderImageType imageType,
  }) {
    _cache.remove(page);

    _cache[page] = PageImageCacheItem(
      data: data,
      width: width,
      height: height,
      quality: quality,
      imageType: imageType,
    );

    _evict();

    _con.add(const PageImageCachePut());
  }

  Uint8List? get(
    int page, {
    required double width,
    required double height,
    required int quality,
    required PageRenderImageType imageType,
  }) {
    final item = _cache[page];

    if (item == null) {
      return null;
    }

    final matches =
        item.width == width &&
        item.height == height &&
        item.quality == quality &&
        item.imageType == imageType;

    if (!matches) {
      _cache.remove(page);
      return null;
    }

    // LRU:
    // ပြန်သုံးတဲ့ item ကို နောက်ဆုံးသို့ ရွှေ့မယ်။
    _cache.remove(page);
    _cache[page] = item;

    return item.data;
  }

  void _evict() {
    while (_cache.isNotEmpty &&
        (_cache.length > maxCount || size > maxSizeBytes)) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  void remove(int page) {
    _cache.remove(page);
    _con.add(PageImageCacheRemove(page));
  }

  void clear() {
    _cache.clear();
    _con.add(const PageImageCacheClear());
  }

  void close() {
    _con.close();
  }
}
