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
  Uint8List? _image;

  StreamSubscription? _subscription;
  Timer? _qualityTimer;

  static const _qualityDebounce = Duration(milliseconds: 150);

  int _requestId = 0;

  int? _lastQuality;
  double? _lastWidth;
  double? _lastHeight;
  PageRenderImageType? _lastImageType;

  @override
  void initState() {
    super.initState();

    _subscription = widget.stateController.stream
        //.whereType<Object>() // ကိုယ့် stream type အတိုင်း ပြင်နိုင်
        .listen(_onStateEvent);

    // Initial render = low quality
    _load(quality: widget.stateController.state.pageImageLowQuality);
  }

  void _onStateEvent(Object event) {
    if (event is ZoomChanged || event is MobileScaleChanged) {
      _scheduleQualityReload();
      return;
    }

    if (event is ScrollEnd || event is UserJumpChanged) {
      _qualityTimer?.cancel();

      // Event ဖြစ်တဲ့အချိန်မှာ latest state ကိုဖတ်
      _reloadHeightQuality();
    }
  }

  void _scheduleQualityReload() {
    _qualityTimer?.cancel();

    _qualityTimer = Timer(_qualityDebounce, _reloadHeightQuality);
  }

  void _reloadHeightQuality() {
    if (!mounted) {
      return;
    }

    final quality = widget.stateController.state.pageImageHeightQuality;

    _load(quality: quality);
  }

  PageRenderImageType _resolveImageType(int quality) {
    final state = widget.stateController.state;

    // Low quality = JPG only
    if (quality == state.pageImageLowQuality) {
      return PageRenderImageType.jpg;
    }

    // High quality = user configured type
    return state.renderImageType;
  }

  Future<void> _load({required int quality}) async {
    // final state = widget.stateController.state;

    final width = widget.offset.width;
    final height = widget.offset.height;

    final imageType = _resolveImageType(quality);

    // အတူတူ image ကို ပြန်မ render နဲ့
    if (_lastQuality == quality &&
        _lastWidth == width &&
        _lastHeight == height &&
        _lastImageType == imageType) {
      return;
    }

    final pageIndex = widget.offset.pageIndex;

    // New request generation
    final requestId = ++_requestId;

    // -------------------------
    // Cache
    // -------------------------

    final cached = widget.imageCache.get(
      pageIndex,
      width: width,
      height: height,
      quality: quality,
      imageType: imageType,
    );

    if (cached != null) {
      if (!mounted || requestId != _requestId) {
        return;
      }

      _lastQuality = quality;
      _lastWidth = width;
      _lastHeight = height;
      _lastImageType = imageType;

      setState(() {
        _image = cached;
      });

      return;
    }

    // -------------------------
    // Render
    // -------------------------

    final image = await widget.worker.getImage(
      pageIndex,
      quality: quality,
      targetHeight: height.toInt(),
      targetWidth: width.toInt(),
      renderImageType: imageType,
    );

    // Request အသစ်တစ်ခုက ဒီ request ကို ကျော်သွားပြီ
    if (!mounted || requestId != _requestId) {
      return;
    }

    // -------------------------
    // Cache
    // -------------------------

    widget.imageCache.put(
      pageIndex,
      image.unwrap(),
      width: width,
      height: height,
      quality: quality,
      imageType: imageType,
    );

    _lastQuality = quality;
    _lastWidth = width;
    _lastHeight = height;
    _lastImageType = imageType;

    setState(() {
      _image = image.unwrap();
    });
  }

  @override
  void dispose() {
    _qualityTimer?.cancel();
    _subscription?.cancel();

    // Pending request တွေကို invalidate
    _requestId++;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final footerBuilder = widget.controller.widgetBuilder.footerBuilder;
    return Column(
      children: [
        Expanded(child: _buildImage()),

        // Footer ရှိရင် ဒီမှာ
        if (footerBuilder != null) footerBuilder(context, widget.offset),

        // _buildFooter(),
      ],
    );
  }

  Widget _buildImage() {
    final image = _image;

    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox.expand(
      child: Image.memory(
        image,
        fit: BoxFit.contain,

        // Image အသစ် decode မပြီးခင်
        // အရင် image ကို ဆက်ပြထားနိုင်အောင်
        gaplessPlayback: true,

        filterQuality: FilterQuality.high,
      ),
    );
  }
}
