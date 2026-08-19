import 'package:dart_core_extensions/dart_core_extensions.dart';
import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class MyReader extends StatefulWidget {
  const MyReader({super.key, required this.path});
  final String path;

  @override
  State<MyReader> createState() => _MyReaderState();
}

class _MyReaderState extends State<MyReader> {
  final controller = TPdfController();

  @override
  void initState() {
    controller.attached.listen((_) {
      controller.stream.imageCache.put.listen((event) {
        print('imageCache: $event');
      });
      controller.stream.ready.listen((event) {
        print('reader ready');
        controller.action.jumpPage(100);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pdf Reader')),
      body: StreamBuilder(
        stream: controller.lifecycle,
        builder: (context, asyncSnapshot) {
          return Stack(
            children: [
              Positioned.fill(
                top: 50,
                child: TPdfReader(path: widget.path, controller: controller),
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
    );
  }

  Widget testHeaderWidget() {
    final col = Theme.of(context).colorScheme;
    return Container(
      color: col.surfaceContainerHighest,
      child: SingleChildScrollView(
        scrollDirection: .horizontal,
        child: Row(
          spacing: 8,
          children: [
            StreamBuilder(
              stream: controller.stream.pageChanged,
              builder: (context, asyncSnapshot) {
                return TextButton(
                  onPressed: () {
                    controller.action.jumpPage(150);
                  },
                  child: Text(
                    '${controller.state.page}/${controller.state.totalPage}',
                  ),
                );
              },
            ),

            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: col.surfaceContainer,
                foregroundColor: col.onSurface,
              ),
              onPressed: () {
                controller.action.setZoom(controller.state.zoom - 0.1);
              },
              icon: Icon(Icons.zoom_out),
            ),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: col.surfaceContainer,
                foregroundColor: col.onSurface,
              ),
              onPressed: () {
                controller.action.setZoom(controller.state.zoom + 0.1);
              },
              icon: Icon(Icons.zoom_in),
            ),
            StreamBuilder(
              stream: controller.stream.zoomChanged,
              builder: (context, asyncSnapshot) {
                return Text(
                  'Zoom: ${controller.state.zoom.toStringAsFixed(4)}',
                );
              },
            ),
            StreamBuilder(
              stream: controller.stream.imageCache.put,
              builder: (context, asyncSnapshot) {
                return Text(
                  '${controller.state.imageCache.count}/${controller.state.imageCache.size.toFileSizeLabel()}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
