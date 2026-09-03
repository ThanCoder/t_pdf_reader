import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';
import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/controllers/types/page_offset.dart';
import 'package:t_pdf_reader/src/reader/t_pdf_reader.dart';
import 'package:t_pdf_reader/src/reader/utils/page_image_cache.dart';
import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';

class ReaderItem extends StatefulWidget {
  const ReaderItem({
    super.key,
    required this.offset,
    required this.stateController,
    required this.worker,
    required this.imageCache,
    required this.controller,
  });

  final PageOffset offset;
  final ReaderStateController stateController;
  final PdfReaderWorker worker;
  final PageImageCache imageCache;
  final TPdfController controller;

  @override
  State<ReaderItem> createState() => _ReaderItemState();
}

class _ReaderItemState extends State<ReaderItem> {
  // ---------------------------------------------------------------------------
  // Image state
  // ---------------------------------------------------------------------------

  Uint8List? _oldImage;
  Uint8List? _newImage;

  // ---------------------------------------------------------------------------
  // Request state
  // ---------------------------------------------------------------------------

  int _requestId = 0;

  int? _lastQuality;
  double? _lastWidth;
  double? _lastHeight;

  StreamSubscription? _stateSubscription;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _listenToReaderState();
    _loadInitialImage();
  }

  @override
  void dispose() {
    // Invalidate any pending request.
    _requestId++;

    _stateSubscription?.cancel();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Reader state listener
  // ---------------------------------------------------------------------------

  void _listenToReaderState() {
    _stateSubscription = widget.stateController.stream
        .where(_shouldReload)
        .listen((_) {
          final state = widget.stateController.state;

          if (!_needsReload(quality: state.pageImageHeightQuality)) {
            return;
          }

          _reload(quality: state.pageImageHeightQuality);
        });
  }

  bool _shouldReload(dynamic event) {
    return event is ZoomChanged ||
        event is MobileScaleChanged ||
        event is ScrollEnd ||
        event is UserJumpChanged;
  }

  // ---------------------------------------------------------------------------
  // Initial load
  // ---------------------------------------------------------------------------

  void _loadInitialImage() {
    final state = widget.stateController.state;

    _load(quality: state.pageImageLowQuality);
  }

  // ---------------------------------------------------------------------------
  // Reload
  // ---------------------------------------------------------------------------

  void _reload({required int quality}) {
    // Current new image becomes the old image while the new resolution
    // is being rendered.
    if (_newImage != null) {
      _oldImage = _newImage;
      _newImage = null;
    }

    // Invalidate old request.
    _requestId++;

    // Remove old cached image.
    widget.imageCache.remove(widget.offset.pageIndex);

    _load(quality: quality);
  }

  // ---------------------------------------------------------------------------
  // Load image
  // ---------------------------------------------------------------------------

  Future<void> _load({required int quality}) async {
    final width = widget.offset.width;
    final height = widget.offset.height;
    final pageIndex = widget.offset.pageIndex;

    // Don't request the same image again.
    if (!_needsReload(quality: quality, width: width, height: height)) {
      return;
    }

    // -------------------------------------------------------------------------
    // Cache
    // -------------------------------------------------------------------------

    final cachedImage = widget.imageCache.get(pageIndex);

    if (cachedImage != null) {
      _setCachedImage(
        cachedImage,
        quality: quality,
        width: width,
        height: height,
      );

      return;
    }

    // -------------------------------------------------------------------------
    // Request
    // -------------------------------------------------------------------------

    final requestId = ++_requestId;

    final renderImageType = _resolveRenderImageType(quality);

    final result = await widget.worker.getImage(
      pageIndex,
      quality: quality,
      targetWidth: width.toInt(),
      targetHeight: height.toInt(),
      renderImageType: renderImageType,
    );

    // Request is no longer valid.
    if (!mounted || requestId != _requestId) {
      return;
    }

    // Worker returned an error.
    if (result.isErr) {
      return;
    }

    final image = result.unwrap();

    // -------------------------------------------------------------------------
    // Save request state only after successful rendering.
    // -------------------------------------------------------------------------

    _lastQuality = quality;
    _lastWidth = width;
    _lastHeight = height;

    // -------------------------------------------------------------------------
    // Cache
    // -------------------------------------------------------------------------

    widget.imageCache.put(pageIndex, image);

    // -------------------------------------------------------------------------
    // Update UI
    // -------------------------------------------------------------------------

    if (!mounted || requestId != _requestId) {
      return;
    }

    setState(() {
      _newImage = image;
    });
  }

  // ---------------------------------------------------------------------------
  // Cache image
  // ---------------------------------------------------------------------------

  void _setCachedImage(
    Uint8List image, {
    required int quality,
    required double width,
    required double height,
  }) {
    _lastQuality = quality;
    _lastWidth = width;
    _lastHeight = height;

    if (!mounted) {
      return;
    }

    setState(() {
      _oldImage = image;
      _newImage = null;
    });
  }

  // ---------------------------------------------------------------------------
  // Image type
  // ---------------------------------------------------------------------------

  PageRenderImageType _resolveRenderImageType(int quality) {
    final state = widget.stateController.state;

    // Low quality rendering is JPG only.
    if (quality == state.pageImageLowQuality) {
      return PageRenderImageType.jpg;
    }

    // High quality uses the user's selected image format.
    return state.renderImageType;
  }

  // ---------------------------------------------------------------------------
  // Reload check
  // ---------------------------------------------------------------------------

  bool _needsReload({required int quality, double? width, double? height}) {
    return _lastQuality != quality ||
        (width != null && _lastWidth != width) ||
        (height != null && _lastHeight != height);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildImage()),
        _buildFooter(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Image
  // ---------------------------------------------------------------------------

  Widget _buildImage() {
    final oldImage = _oldImage;
    final newImage = _newImage;

    if (oldImage == null && newImage == null) {
      return _buildPlaceholder();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (oldImage != null) _buildMemoryImage(oldImage),

        if (newImage != null) _buildMemoryImage(newImage),
      ],
    );
  }

  Widget _buildMemoryImage(Uint8List image) {
    return Image.memory(image, fit: BoxFit.fill, gaplessPlayback: true);
  }

  // ---------------------------------------------------------------------------
  // Placeholder
  // ---------------------------------------------------------------------------

  Widget _buildPlaceholder() {
    final placeholderBuilder =
        widget.controller.widgetBuilder.placeholderBuilder;

    if (placeholderBuilder != null) {
      return placeholderBuilder(context);
    }

    final iconSize = min(widget.offset.width, widget.offset.height) * 0.4;

    return Icon(Icons.image_not_supported_rounded, size: iconSize);
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter() {
    final footerBuilder = widget.controller.widgetBuilder.footerBuilder;

    if (footerBuilder == null) {
      return const SizedBox.shrink();
    }

    return footerBuilder(context, widget.offset);
  }
}
