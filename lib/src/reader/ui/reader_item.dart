import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:than_pdf_engine/core/high_level_api/reader/pdf_reader_worker.dart';
import 'package:than_pdf_engine/core/low_level_api/pdf_document.dart';
import 'package:t_pdf_reader/src/reader/controllers/reader_state_controller.dart';
import 'package:t_pdf_reader/src/reader/controllers/types/page_offset.dart';
import 'package:t_pdf_reader/src/reader/t_pdf_reader.dart';
import 'package:t_pdf_reader/src/reader/utils/page_image_cache.dart';

class ReaderItem extends StatefulWidget {
  final PageOffset offset;
  final ReaderStateController stateController;
  final PdfReaderWorker worker;
  final PageImageCache imageCache;
  final TPdfController controller;

  const ReaderItem({
    super.key,
    required this.offset,
    required this.stateController,
    required this.worker,
    required this.imageCache,
    required this.controller,
  });

  @override
  State<ReaderItem> createState() => _ReaderItemState();
}

class _ReaderItemState extends State<ReaderItem> {
  Uint8List? _lowQualityImage;
  Uint8List? _highQualityImage;

  StreamSubscription? _subscription;
  StreamSubscription? _visiblePageSub;

  Timer? _lowQualityTimer;
  Timer? _highQualityTimer;

  int _lowRequestId = 0;
  int _highRequestId = 0;

  double? _lastWidth;
  double? _lastHeight;

  /// User zoom / scale လုပ်နေတုန်း
  /// ချက်ချင်း LOW render မလုပ်ဘဲ
  /// ဒီအချိန်လောက် ငြိမ်သွားမှ render လုပ်မယ်။
  static const _lowQualityDelay = Duration(milliseconds: 150);

  /// LOW ပြီးသွားပြီး
  /// HIGH မစခင် စောင့်မယ့်အချိန်။
  static const _highQualityDelay = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();

    // --------------------------------
    // Visible page event
    // --------------------------------

    _visiblePageSub = widget.stateController.stream
        .whereType<UpdateVisiblePages>()
        .listen((_) {
          _checkVisible();
        });

    // --------------------------------
    // State events
    // --------------------------------

    _subscription = widget.stateController.stream.listen(_onStateEvent);

    // --------------------------------
    // Initial LOW
    // --------------------------------

    _loadLowQuality();
  }

  // ============================================================
  // Visible Page
  // ============================================================

  void _checkVisible() {
    if (!mounted) {
      return;
    }

    final visiblePages = widget.stateController.state.visiablePages;

    final pageIndex = widget.offset.pageIndex;

    if (!visiblePages.contains(pageIndex)) {
      // Visible မဟုတ်တော့ရင် pending HIGH ကို cancel
      // လုပ်ထားတာက ပိုကောင်းတယ်။
      _highQualityTimer?.cancel();

      return;
    }

    // LOW ရပြီးမှ HIGH schedule လုပ်မယ်။
    if (_lowQualityImage != null) {
      _scheduleHighQuality();
    }
  }

  // ============================================================
  // State Event
  // ============================================================

  void _onStateEvent(Object event) {
    // --------------------------------
    // Zoom / Mobile Scale
    // --------------------------------

    if (event is ZoomChanged || event is MobileScaleChanged) {
      _scheduleLowQuality();
      return;
    }

    // --------------------------------
    // User Jump
    // --------------------------------

    if (event is UserJumpChanged) {
      _scheduleLowQuality();
      return;
    }

    // --------------------------------
    // Scroll End
    // --------------------------------

    if (event is ScrollEnd) {
      _scheduleLowQuality();
      return;
    }
  }

  // ============================================================
  // Schedule LOW
  // ============================================================

  void _scheduleLowQuality() {
    if (!mounted) {
      return;
    }

    // User က ဆက် zoom / scale / jump လုပ်နေသရွေ့
    // timer ကို reset လုပ်မယ်။
    _lowQualityTimer?.cancel();

    // HIGH pending ဖြစ်နေရင်လည်း cancel။
    //
    // လက်ရှိ layout မတည်ငြိမ်သေးတဲ့အတွက်
    // HQ ကို မစသင့်သေးဘူး။
    _highQualityTimer?.cancel();

    _lowQualityTimer = Timer(_lowQualityDelay, _loadLowQuality);
  }

  // ============================================================
  // Schedule HIGH
  // ============================================================

  void _scheduleHighQuality() {
    if (!mounted) {
      return;
    }

    if (_lowQualityImage == null) {
      return;
    }

    if (_highQualityImage != null) {
      return;
    }

    final visiblePages = widget.stateController.state.visiablePages;

    if (!visiblePages.contains(widget.offset.pageIndex)) {
      return;
    }

    _highQualityTimer?.cancel();

    _highQualityTimer = Timer(_highQualityDelay, _loadHighQuality);
  }

  // ============================================================
  // LOW QUALITY
  // ============================================================

  Future<void> _loadLowQuality() async {
    if (!mounted) {
      return;
    }

    final state = widget.stateController.state;

    final quality = state.pageImageLowQuality;

    final width = widget.offset.width;
    final height = widget.offset.height;

    const imageType = PageRenderImageType.jpg;

    // --------------------------------
    // Same size
    // --------------------------------

    if (_lastWidth == width && _lastHeight == height) {
      if (_lowQualityImage != null) {
        _scheduleHighQuality();
      }

      return;
    }

    final pageIndex = widget.offset.pageIndex;

    final requestId = ++_lowRequestId;

    // --------------------------------
    // Cache
    // --------------------------------

    final cached = widget.imageCache.get(
      pageIndex,
      width: width,
      height: height,
      quality: quality,
      imageType: imageType,
    );

    if (cached != null) {
      if (!mounted || requestId != _lowRequestId) {
        return;
      }

      _lastWidth = width;
      _lastHeight = height;

      // Size ပြောင်းသွားတဲ့အတွက်
      // old HQ ကို မပြသင့်တော့ဘူး။
      _highQualityImage = null;
      _highRequestId++;

      setState(() {
        _lowQualityImage = cached;
      });

      // LOW ပြီးပြီ။
      // Visible ဖြစ်ရင် HQ schedule.
      _scheduleHighQuality();

      return;
    }

    // --------------------------------
    // Render LOW
    // --------------------------------

    final image = await widget.worker.getImage(
      pageIndex,
      quality: quality,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
      renderImageType: imageType,
    );

    if (!mounted || requestId != _lowRequestId) {
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
      imageType: imageType,
    );

    _lastWidth = width;
    _lastHeight = height;

    // Old HQ ကို invalidate လုပ်မယ်။
    _highQualityImage = null;
    _highRequestId++;

    setState(() {
      _lowQualityImage = bytes;
    });

    // --------------------------------
    // LOW ပြီးပြီ
    // --------------------------------

    _scheduleHighQuality();
  }

  // ============================================================
  // HIGH QUALITY
  // ============================================================

  Future<void> _loadHighQuality() async {
    if (!mounted) {
      return;
    }

    // LOW မပြီးသေးရင် မလုပ်ပါနဲ့။
    if (_lowQualityImage == null) {
      return;
    }

    // HIGH ရှိပြီးသား
    if (_highQualityImage != null) {
      return;
    }

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

    final requestId = ++_highRequestId;

    // --------------------------------
    // Render HIGH
    // --------------------------------

    final image = await widget.worker.getImage(
      pageIndex,
      quality: quality,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
      renderImageType: imageType,
    );

    if (!mounted || requestId != _highRequestId) {
      return;
    }

    // --------------------------------
    // HIGH = memory only
    // --------------------------------

    final bytes = image.unwrap();

    _highQualityImage = bytes;

    setState(() {});
  }

  // ============================================================
  // Dispose
  // ============================================================

  @override
  void dispose() {
    _lowQualityTimer?.cancel();
    _highQualityTimer?.cancel();

    _lowRequestId++;
    _highRequestId++;

    // HIGH က ReaderItem lifetime ပဲ။
    _highQualityImage = null;

    _subscription?.cancel();
    _visiblePageSub?.cancel();

    super.dispose();
  }

  // ============================================================
  // Build
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
  // Image
  // ============================================================

  Widget _buildImage() {
    final image = _highQualityImage ?? _lowQualityImage;

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
