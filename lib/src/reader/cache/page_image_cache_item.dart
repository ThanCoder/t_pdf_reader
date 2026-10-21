// ignore_for_file: public_member_api_docs
part of 'page_image_cache.dart';
class PageImageCacheItem {
  final Uint8List data;
  final double width;
  final double height;

  const PageImageCacheItem({
    required this.data,
    required this.width,
    required this.height,
  });
}
