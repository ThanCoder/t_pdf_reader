// ignore_for_file: public_member_api_docs

part of 'page_image_cache.dart';

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
