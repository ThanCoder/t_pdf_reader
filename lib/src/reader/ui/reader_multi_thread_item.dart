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
  Uint8List? _lowQualityImage;
  Uint8List? _highQualityImage;
  Uint8List? _lastHighQualityImage;

  double? _lastWidth;
  double? _lastHeight;

  StreamSubscription? _subscription;
  StreamSubscription? _visiblePageSub;

  final loadHighImageDelay = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _visiblePageSub = widget.stateController.stream
        .whereType<UpdateVisiblePages>()
        .listen((_) => _checkVisible());

    // --------------------------------
    // State events
    // --------------------------------

    _subscription = widget.stateController.stream.listen(_onStateEvent);

    // --------------------------------
    // Initial LOW
    // --------------------------------

    _loadLowQuality();
  }

  @override
  void dispose() {
    // HIGH က ReaderSingleThreadItem lifetime ပဲ။
    _highQualityImage = null;

    _subscription?.cancel();
    _visiblePageSub?.cancel();

    super.dispose();
  }

  void _checkVisible() {
    if (!mounted) return;

    final visiblePages = widget.stateController.state.visiablePages;

    final pageIndex = widget.offset.pageIndex;

    if (!visiblePages.contains(pageIndex)) {
      // Visible မဟုတ်တော့ရင် pending HIGH ကို cancel
      // လုပ်ထားတာက ပိုကောင်းတယ်။
      // _highQualityTimer?.cancel();
      _loadHighQualityDelayTimer?.cancel();
      return;
    }

    // LOW ရပြီးမှ HIGH schedule လုပ်မယ်။
    if (_lowQualityImage != null) {
      // _scheduleHighQuality();
    }
    _loadHighQualityDelay();
  }

  void _onStateEvent(Object event) {
    // --------------------------------
    // Zoom / Mobile Scale
    // --------------------------------

    if (event is ZoomChanged || event is MobileScaleChanged) {
      _lastHighQualityImage = _highQualityImage;
      _highQualityImage = null;
      _loadHighQualityDelay();
      return;
    }

    // --------------------------------
    // User Jump
    // --------------------------------

    if (event is UserJumpChanged) {
      _loadHighQualityDelay();
      return;
    }

    // --------------------------------
    // Scroll End
    // --------------------------------

    if (event is ScrollEnd) {
      _loadHighQualityDelay();
      return;
    }
  }

  Future<void> _loadLowQuality() async {
    if (!mounted) return;

    final state = widget.stateController.state;

    final quality = state.pageImageLowQuality;

    final width = widget.offset.width;
    final height = widget.offset.height;
    final pageIndex = widget.offset.pageIndex;
    final imageType = widget.stateController.state.renderImageType;

    if (width == _lastWidth &&
        height == _lastHeight &&
        _lowQualityImage != null) {
      //get height image
      _loadHighQuality();
      return;
    }
    final cached = widget.imageCache.get(
      pageIndex,
      width: width,
      height: height,
    );
    if (cached != null) {
      _lowQualityImage = cached;
      _lastHeight = width;
      _lastHeight = height;
      _highQualityImage = null;

      setState(() {});
      _loadHighQuality();
      return;
    }

    // get image
    final image = await widget.worker.getImageLowQuality(
      pageIndex,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
      quality: quality,
      renderImageType: imageType,
    );

    if (!mounted) {
      return;
    }

    final bytes = image.unwrap();

    // --------------------------------
    // Cache LOW
    // --------------------------------

    widget.imageCache.put(
      pageIndex,
      bytes,
      width: width,
      height: height,
      quality: quality,
    );

    _lastWidth = width;
    _lastHeight = height;

    setState(() {
      _lowQualityImage = bytes;
    });
    _loadHighQuality();
  }

  Timer? _loadHighQualityDelayTimer;

  Future<void> _loadHighQualityDelay() async {
    _loadHighQualityDelayTimer?.cancel();
    _loadHighQualityDelayTimer = Timer(loadHighImageDelay, () {
      if (!mounted) return;
      _loadHighQuality();
    });
  }

  Future<void> _loadHighQuality() async {
    if (!mounted) return;

    // LOW မပြီးသေးရင် မလုပ်ပါနဲ့။
    if (_lowQualityImage == null) return;

    // HIGH ရှိပြီးသား
    if (_highQualityImage != null) return;

    // လက်ရှိ page က REAL visible ဖြစ်သေးလား
    final visiblePages = widget.stateController.state.visiablePages;

    if (!visiblePages.contains(widget.offset.pageIndex)) {
      return;
    }

    final state = widget.stateController.state;

    final quality = state.pageImageHeightQuality;

    final width = widget.offset.width;
    final height = widget.offset.height;

    final imageType = state.renderImageType;

    final pageIndex = widget.offset.pageIndex;

    // --------------------------------
    // Render HIGH
    // --------------------------------
    final image = await widget.worker.getImageHighQuality(
      pageIndex,
      quality: quality,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
      renderImageType: imageType,
    );

    if (!mounted) {
      return;
    }

    // --------------------------------
    // HIGH = memory only
    // --------------------------------

    final bytes = image.unwrap();

    _highQualityImage = bytes;

    setState(() {});
  }

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
  // Image
  // ============================================================

  Widget _buildImage() {
    final image =
        _lastHighQualityImage ?? (_highQualityImage ?? _lowQualityImage);

    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox.expand(
      child: Image.memory(
        image,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
