import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:t_pdf_reader/src/reader/page_image_worker/i_page_image_worker.dart';
import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/controllers/types/page_offset.dart';
import 'package:t_pdf_reader/src/reader/t_pdf_reader.dart';
import 'package:t_pdf_reader/src/reader/cache/page_image_cache.dart';

class ReaderMultiThreadItem extends StatefulWidget {
  const new({
    super.key,
    required this.offset,
    required this.stateController,
    required this.worker,
    required this.imageCache,
    required this.controller,
  });

  final PageOffset offset;
  final ReaderStateController stateController;
  final IPageImageWorker worker;
  final PageImageCache imageCache;
  final TPdfController controller;

  @override
  State<ReaderMultiThreadItem> createState() => _ReaderMultiThreadItemState();
}

class _ReaderMultiThreadItemState extends State<ReaderMultiThreadItem> {
  // ============================================================
  // Images
  // ============================================================

  Uint8List? _lowQualityImage;

  Uint8List? _highQualityImage;

  /// Previous HIGH image.
  ///
  /// This is only used while a new HIGH image is rendering.
  Uint8List? _lastHighQualityImage;

  // ============================================================
  // LOW image size
  // ============================================================

  double? _lastWidth;
  double? _lastHeight;

  // ============================================================
  // State subscriptions
  // ============================================================

  StreamSubscription? _stateSubscription;
  StreamSubscription? _visiblePageSubscription;

  // ============================================================
  // HIGH delay
  // ============================================================

  Timer? _loadHighImageDelayTimer;

  static const _loadHighImageDelay = Duration(milliseconds: 300);

  // ============================================================
  // Request generation
  // ============================================================

  /// HIGH request generation.
  ///
  /// Every new HIGH request increments this value.
  ///
  /// This prevents an old async HIGH result from replacing
  /// a newer HIGH result.
  int _highRequestGeneration = 0;

  /// LOW request generation.
  ///
  /// Prevents an old LOW request from replacing a newer LOW
  /// request after zoom/size changes.
  int _lowRequestGeneration = 0;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ----------------------------------------------------------
    // Visible pages
    // ----------------------------------------------------------

    _visiblePageSubscription = widget.stateController.stream
        .where((event) => event is UpdateVisiblePages)
        .listen((_) {
          _checkVisible();
        });

    // ----------------------------------------------------------
    // State events
    // ----------------------------------------------------------

    _stateSubscription = widget.stateController.stream.listen(_onStateEvent);

    // ----------------------------------------------------------
    // Start LOW and HIGH independently.
    //
    // IMPORTANT:
    // HIGH does NOT wait for LOW.
    // ----------------------------------------------------------

    _loadLowQuality();

    _checkVisible();
  }

  @override
  void dispose() {
    // Invalidate all running requests.
    _lowRequestGeneration++;
    _highRequestGeneration++;

    _loadHighImageDelayTimer?.cancel();

    _stateSubscription?.cancel();
    _visiblePageSubscription?.cancel();

    _lowQualityImage = null;
    _highQualityImage = null;
    _lastHighQualityImage = null;

    super.dispose();
  }

  // ============================================================
  // Visible
  // ============================================================

  void _checkVisible() {
    if (!mounted) return;

    final visiblePages = widget.stateController.state.visiablePages;

    final pageIndex = widget.offset.pageIndex;

    if (!visiblePages.contains(pageIndex)) {
      // --------------------------------------------------------
      // Not visible.
      // --------------------------------------------------------

      _loadHighImageDelayTimer?.cancel();

      // Invalidate HIGH request.
      _highRequestGeneration++;

      return;
    }

    // ----------------------------------------------------------
    // Visible.
    //
    // HIGH is delayed slightly to avoid rendering every page
    // immediately while scrolling.
    // ----------------------------------------------------------

    _loadHighQualityDelay();
  }

  // ============================================================
  // State events
  // ============================================================

  void _onStateEvent(Object event) {
    // ----------------------------------------------------------
    // Zoom / Mobile Scale
    // ----------------------------------------------------------

    if (event is ZoomChanged || event is MobileScaleChanged) {
      _loadHighImageDelayTimer?.cancel();

      // --------------------------------------------------------
      // Keep previous HIGH while new HIGH is rendering.
      // --------------------------------------------------------

      _lastHighQualityImage = _highQualityImage;

      _highQualityImage = null;

      // --------------------------------------------------------
      // Invalidate old requests.
      // --------------------------------------------------------

      _lowRequestGeneration++;
      _highRequestGeneration++;

      // --------------------------------------------------------
      // LOW must also be loaded for the new size.
      // --------------------------------------------------------

      _loadLowQuality();

      // --------------------------------------------------------
      // HIGH will start after the delay.
      // --------------------------------------------------------

      _loadHighQualityDelay();

      if (mounted) {
        setState(() {});
      }

      return;
    }

    // ----------------------------------------------------------
    // User Jump
    // ----------------------------------------------------------

    if (event is UserJumpChanged) {
      _loadHighQualityDelay();
      return;
    }

    // ----------------------------------------------------------
    // Scroll End
    // ----------------------------------------------------------

    if (event is ScrollEnd) {
      _loadHighQualityDelay();
      return;
    }
  }

  // ============================================================
  // LOW QUALITY
  // ============================================================

  Future<void> _loadLowQuality() async {
    if (!mounted) return;

    final state = widget.stateController.state;

    final quality = state.pageImageLowQuality;

    final width = widget.offset.width;
    final height = widget.offset.height;

    final pageIndex = widget.offset.pageIndex;

    final imageType = state.renderImageType;

    // ----------------------------------------------------------
    // Request generation
    // ----------------------------------------------------------

    final requestGeneration = ++_lowRequestGeneration;

    // ----------------------------------------------------------
    // Same LOW already loaded.
    // ----------------------------------------------------------

    if (_lastWidth == width &&
        _lastHeight == height &&
        _lowQualityImage != null) {
      return;
    }

    // ----------------------------------------------------------
    // Check LOW cache.
    // ----------------------------------------------------------

    final cached = widget.imageCache.get(
      pageIndex,
      width: width,
      height: height,
    );

    if (cached != null) {
      if (!mounted) return;

      if (requestGeneration != _lowRequestGeneration) {
        return;
      }

      _lastWidth = width;
      _lastHeight = height;

      _lowQualityImage = cached;

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // Do NOT clear HIGH here.
      //
      // HIGH may already have arrived before LOW.
      // --------------------------------------------------------

      if (mounted) {
        setState(() {});
      }

      return;
    }

    // ----------------------------------------------------------
    // Render LOW
    // ----------------------------------------------------------

    final image = await widget.worker.getImageLowQuality(
      pageIndex,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
      quality: quality,
      renderImageType: imageType,
    );

    if (!mounted) return;

    // ----------------------------------------------------------
    // Old request?
    // ----------------------------------------------------------

    if (requestGeneration != _lowRequestGeneration) {
      return;
    }

    final bytes = image.unwrap();

    // ----------------------------------------------------------
    // Cache LOW
    // ----------------------------------------------------------

    widget.imageCache.put(
      pageIndex,
      bytes,
      width: width,
      height: height,
      quality: quality,
    );

    // ----------------------------------------------------------
    // Save LOW
    // ----------------------------------------------------------

    _lastWidth = width;
    _lastHeight = height;

    _lowQualityImage = bytes;

    // ----------------------------------------------------------
    // IMPORTANT:
    //
    // Do NOT touch _highQualityImage here.
    //
    // HIGH may have already arrived.
    // ----------------------------------------------------------

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // HIGH QUALITY DELAY
  // ============================================================

  void _loadHighQualityDelay() {
    _loadHighImageDelayTimer?.cancel();

    _loadHighImageDelayTimer = Timer(_loadHighImageDelay, () {
      if (!mounted) return;

      _loadHighQuality();
    });
  }

  // ============================================================
  // HIGH QUALITY
  // ============================================================

  Future<void> _loadHighQuality() async {
    if (!mounted) return;

    // ----------------------------------------------------------
    // HIGH does NOT depend on LOW.
    //
    // There is intentionally NO:
    //
    // if (_lowQualityImage == null) return;
    //
    // ----------------------------------------------------------

    // ----------------------------------------------------------
    // Already have HIGH.
    // ----------------------------------------------------------

    if (_highQualityImage != null) {
      return;
    }

    // ----------------------------------------------------------
    // Page must be visible.
    // ----------------------------------------------------------

    final state = widget.stateController.state;

    final visiblePages = state.visiablePages;

    final pageIndex = widget.offset.pageIndex;

    if (!visiblePages.contains(pageIndex)) {
      return;
    }

    // ----------------------------------------------------------
    // Request generation
    // ----------------------------------------------------------

    final requestGeneration = ++_highRequestGeneration;

    // ----------------------------------------------------------
    // Render parameters
    // ----------------------------------------------------------

    final quality = state.pageImageHeightQuality;

    final width = widget.offset.width;
    final height = widget.offset.height;

    final imageType = state.renderImageType;

    // ----------------------------------------------------------
    // Render HIGH
    //
    // This can run while LOW is still loading.
    // ----------------------------------------------------------

    final image = await widget.worker.getImageHighQuality(
      pageIndex,
      quality: quality,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
      renderImageType: imageType,
    );

    if (!mounted) return;

    // ----------------------------------------------------------
    // Old request?
    // ----------------------------------------------------------

    if (requestGeneration != _highRequestGeneration) {
      return;
    }

    // ----------------------------------------------------------
    // Page no longer visible?
    // ----------------------------------------------------------

    final currentVisiblePages = widget.stateController.state.visiablePages;

    if (!currentVisiblePages.contains(pageIndex)) {
      return;
    }

    final bytes = image.unwrap();

    // ----------------------------------------------------------
    // HIGH arrived first or after LOW.
    //
    // HIGH always wins.
    // ----------------------------------------------------------

    _lastHighQualityImage = null;

    _highQualityImage = bytes;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final footerBuilder = widget.controller.widgetBuilder.footerBuilder;

    return Column(
      children: [
        Expanded(child: _buildImage()),

        if (footerBuilder != null) footerBuilder(context, widget.offset),
      ],
    );
  }

  // ============================================================
  // IMAGE
  // ============================================================

  Widget _buildImage() {
    /*
    print(
      'ReaderMultiThreadItem '
      'page=${widget.offset.pageIndex} '
      'low=${_lowQualityImage?.length} '
      'high=${_highQualityImage?.length} '
      'lastHigh=${_lastHighQualityImage?.length}',
    );
    */

    // ----------------------------------------------------------
    // Priority:
    //
    // 1. New HIGH
    // 2. Previous HIGH
    // 3. LOW
    // ----------------------------------------------------------

    final image =
        _highQualityImage ?? _lastHighQualityImage ?? _lowQualityImage;

    if (image == null) {
      final pageImageLoadingBuilder =
          widget.controller.widgetBuilder.pageImageLoadingBuilder;
      if (pageImageLoadingBuilder != null) {
        return Center(child: pageImageLoadingBuilder(context, widget.offset));
      }
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox.expand(
      child: Image.memory(
        image,
        fit: BoxFit.fitWidth,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
