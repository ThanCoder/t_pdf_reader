// import 'dart:async';
// import 'dart:math';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';
// import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';
// import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
// import 'package:t_pdf_reader/src/reader/controllers/types/page_offset.dart';
// import 'package:t_pdf_reader/src/reader/t_pdf_reader.dart';
// import 'package:t_pdf_reader/src/reader/utils/page_image_cache.dart';

// class ReaderItem extends StatefulWidget {
//   const ReaderItem({
//     super.key,
//     required this.offset,
//     required this.stateController,
//     required this.worker,
//     required this.imageCache,
//     required this.controller,
//   });

//   final PageOffset offset;
//   final ReaderStateController stateController;
//   final PdfReaderWorker worker;
//   final PageImageCache imageCache;
//   final TPdfController controller;

//   @override
//   State<ReaderItem> createState() => _ReaderItemState();
// }

// class _ReaderItemState extends State<ReaderItem> {
//   // ---------------------------------------------------------------------------
//   // Image
//   // ---------------------------------------------------------------------------

//   Uint8List? _oldImage;
//   Uint8List? _newImage;

//   // ---------------------------------------------------------------------------
//   // Last rendered configuration
//   // ---------------------------------------------------------------------------

//   int? _lastQuality;
//   double? _lastWidth;
//   double? _lastHeight;

//   // ---------------------------------------------------------------------------
//   // Request
//   // ---------------------------------------------------------------------------

//   int _requestId = 0;

//   // ---------------------------------------------------------------------------
//   // Debounce
//   // ---------------------------------------------------------------------------

//   Timer? _qualityTimer;

//   static const _qualityDebounce = Duration(milliseconds: 150);

//   // ---------------------------------------------------------------------------
//   // State subscription
//   // ---------------------------------------------------------------------------

//   StreamSubscription? _stateSubscription;

//   // ---------------------------------------------------------------------------
//   // Lifecycle
//   // ---------------------------------------------------------------------------

//   @override
//   void initState() {
//     super.initState();

//     _listenToReaderState();

//     _load(quality: widget.stateController.state.pageImageLowQuality);
//   }

//   @override
//   void dispose() {
//     _qualityTimer?.cancel();

//     _stateSubscription?.cancel();

//     // Invalidate pending request.
//     _requestId++;

//     super.dispose();
//   }

//   // ---------------------------------------------------------------------------
//   // Reader state
//   // ---------------------------------------------------------------------------

//   void _listenToReaderState() {
//     _stateSubscription = widget.stateController.stream
//         .where(_isResolutionChangeEvent)
//         .listen((_) {
//           _scheduleHighQualityReload();
//         });
//   }

//   bool _isResolutionChangeEvent(dynamic event) {
//     return event is ZoomChanged ||
//         event is MobileScaleChanged ||
//         event is ScrollEnd ||
//         event is UserJumpChanged;
//   }

//   // ---------------------------------------------------------------------------
//   // Schedule high quality rendering
//   // ---------------------------------------------------------------------------

//   void _scheduleHighQualityReload() {
//     _qualityTimer?.cancel();

//     _qualityTimer = Timer(_qualityDebounce, _loadCurrentHighQuality);
//   }

//   void _loadCurrentHighQuality() {
//     if (!mounted) {
//       return;
//     }

//     final quality = widget.stateController.state.pageImageHeightQuality;

//     _reload(quality: quality);
//   }

//   // ---------------------------------------------------------------------------
//   // Reload
//   // ---------------------------------------------------------------------------

//   void _reload({required int quality}) {
//     // Keep the current image visible while rendering.
//     if (_newImage != null) {
//       _oldImage = _newImage;
//       _newImage = null;
//     }

//     // Invalidate previous request.
//     _requestId++;

//     // Current cache belongs to the previous resolution.
//     widget.imageCache.remove(widget.offset.pageIndex);

//     _load(quality: quality);
//   }

//   // ---------------------------------------------------------------------------
//   // Load
//   // ---------------------------------------------------------------------------

//   Future<void> _load({required int quality}) async {
//     final pageIndex = widget.offset.pageIndex;
//     final width = widget.offset.width;
//     final height = widget.offset.height;

//     // Nothing changed.
//     if (_lastQuality == quality &&
//         _lastWidth == width &&
//         _lastHeight == height) {
//       return;
//     }

//     // -------------------------------------------------------------------------
//     // Cache
//     // -------------------------------------------------------------------------

//     final cachedImage = widget.imageCache.get(pageIndex);

//     if (cachedImage != null) {
//       _showImage(cachedImage, quality: quality, width: width, height: height);

//       return;
//     }

//     // -------------------------------------------------------------------------
//     // Request
//     // -------------------------------------------------------------------------

//     final requestId = ++_requestId;

//     final renderImageType = _resolveRenderImageType(quality);

//     final result = await widget.worker.getImage(
//       pageIndex,
//       quality: quality,
//       targetWidth: width.toInt(),
//       targetHeight: height.toInt(),
//       renderImageType: renderImageType,
//     );

//     // Request is outdated.
//     if (!mounted || requestId != _requestId) {
//       return;
//     }

//     if (result.isErr) {
//       return;
//     }

//     final image = result.unwrap();

//     // -------------------------------------------------------------------------
//     // Save state
//     // -------------------------------------------------------------------------

//     _lastQuality = quality;
//     _lastWidth = width;
//     _lastHeight = height;

//     // -------------------------------------------------------------------------
//     // Cache
//     // -------------------------------------------------------------------------

//     widget.imageCache.put(pageIndex, image);

//     // -------------------------------------------------------------------------
//     // Display
//     // -------------------------------------------------------------------------

//     setState(() {
//       _newImage = image;
//     });
//   }

//   // ---------------------------------------------------------------------------
//   // Show cached image
//   // ---------------------------------------------------------------------------

//   void _showImage(
//     Uint8List image, {
//     required int quality,
//     required double width,
//     required double height,
//   }) {
//     _lastQuality = quality;
//     _lastWidth = width;
//     _lastHeight = height;

//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       _oldImage = image;
//       _newImage = null;
//     });
//   }

//   // ---------------------------------------------------------------------------
//   // Render type
//   // ---------------------------------------------------------------------------

//   PageRenderImageType _resolveRenderImageType(int quality) {
//     final state = widget.stateController.state;

//     // Low quality is always JPG.
//     if (quality == state.pageImageLowQuality) {
//       return PageRenderImageType.jpg;
//     }

//     // High quality uses selected format.
//     return state.renderImageType;
//   }

//   // ---------------------------------------------------------------------------
//   // Build
//   // ---------------------------------------------------------------------------

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Expanded(child: _buildImage()),
//         _buildFooter(),
//       ],
//     );
//   }

//   // ---------------------------------------------------------------------------
//   // Image
//   // ---------------------------------------------------------------------------

//   Widget _buildImage() {
//     final oldImage = _oldImage;
//     final newImage = _newImage;

//     if (oldImage == null && newImage == null) {
//       return _buildPlaceholder();
//     }

//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         if (oldImage != null) _buildMemoryImage(oldImage),

//         if (newImage != null) _buildMemoryImage(newImage),
//       ],
//     );
//   }

//   Widget _buildMemoryImage(Uint8List image) {
//     return Image.memory(image, fit: BoxFit.fill, gaplessPlayback: true);
//   }

//   // ---------------------------------------------------------------------------
//   // Placeholder
//   // ---------------------------------------------------------------------------

//   Widget _buildPlaceholder() {
//     final placeholderBuilder =
//         widget.controller.widgetBuilder.placeholderBuilder;

//     if (placeholderBuilder != null) {
//       return placeholderBuilder(context);
//     }

//     final iconSize = min(widget.offset.width, widget.offset.height) * 0.4;

//     return Icon(Icons.image_not_supported_rounded, size: iconSize);
//   }

//   // ---------------------------------------------------------------------------
//   // Footer
//   // ---------------------------------------------------------------------------

//   Widget _buildFooter() {
//     final footerBuilder = widget.controller.widgetBuilder.footerBuilder;

//     if (footerBuilder == null) {
//       return const SizedBox.shrink();
//     }

// ignore_for_file: file_names

//     return footerBuilder(context, widget.offset);
//   }
// }
