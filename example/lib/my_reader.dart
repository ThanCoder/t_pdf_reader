// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class MyReader extends StatefulWidget {
  const MyReader({super.key, required this.path});
  final String path;

  @override
  State<MyReader> createState() => _MyReaderState();
}

class _MyReaderState extends State<MyReader> {
  late final TPdfController controller;

  @override
  void initState() {
    controller = TPdfController(
      widgetBuilder: TPdfWidgetBuilder(
        footerBuilder: (context, pageOffset) => Container(
          width: pageOffset.width,
          color: Colors.white,
          child: Center(
            child: Text(
              'Page: ${pageOffset.pageIndex + 1}',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
        scrollbarBuilder: (context, page) {
          return .new(
            widgetInfo: .new(thumbWidth: 20, thumbHeight: 40),
            builder: defaultScrollbarGlow(thumbWidth: 20, thumbHeight: 40),
          );
        },
      ),
      eventBuilder: .new(
        onKeyEventAfterConfig: (node, event) {
          if (event is KeyDownEvent) {
            if (event.physicalKey == .arrowDown) {
              print('custom down');
              return .handled;
            }
          }
          return .ignored;
        },
      ),
    );
    controller.attached.listen((_) {
      controller.stream.ready.listen((event) {
        controller.action.setFitZoom();
        print('reader ready');
        // controller.action.jumpPage(100);
        // controller.action.setZoom(1.7000000000000006);
        // controller.action.
      });
      controller.stream.zoomChanged.listen((_) {
        print(
          'zoom: ${controller.state.zoom} - currentOffsetX: ${controller.state.currentOffsetX}',
        );
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: .dark(),
      child: Scaffold(
        appBar: AppBar(title: Text('Pdf Reader')),
        body: StreamBuilder(
          stream: controller.attached,
          builder: (context, asyncSnapshot) {
            return Stack(
              children: [
                Positioned.fill(
                  top: 50,
                  child: ColorFiltered(
                    colorFilter: .mode(
                      Colors.white,
                      darkMode ? .difference : .dstIn,
                    ),
                    child: TPdfReader(
                      path: widget.path,
                      controller: controller,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 50,
                  child: testHeaderWidget(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget testHeaderWidget() {
    return Builder(
      builder: (context) {
        final col = Theme.of(context).colorScheme;
        return Container(
          color: col.surfaceContainer,
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            child: Row(
              spacing: 8,
              children: [
                PdfPageListener(controller: controller, onClicked: jumpPage),
                PdfZoomOut(controller: controller),
                PdfZoomIn(controller: controller),
                PdfZoomListener(controller: controller),
                IconButton(
                  onPressed: () {
                    darkMode = !darkMode;
                    setState(() {});
                  },
                  icon: Icon(
                    darkMode
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                  ),
                ),
                PdfScrollbarToggler(controller: controller),
                PdfCacheImageListener(controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }

  void jumpPage() {
    showDialog(
      context: context,
      builder: (context) => PdfPageJumpDialog(controller: controller),
    );
  }
}
