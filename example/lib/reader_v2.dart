// ignore_for_file: unused_element, avoid_print, use_build_context_synchronously

import 'package:dart_core_extensions/dart_core_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';
import 'package:t_widgets/t_widgets.dart';
import 'package:than_pkg/than_pkg.dart';

class ReaderV2 extends StatefulWidget {
  final String path;
  const ReaderV2({super.key, required this.path});

  @override
  State<ReaderV2> createState() => _ReaderV2State();
}

class _ReaderV2State extends State<ReaderV2> {
  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    ThanPkg.platform.toggleFullScreen(isFullScreen: false);
    // pdfController.dispose();
    super.dispose();
  }

  bool isDarkMode = false;
  bool isScaleEnable = false;
  bool isFullscreen = false;
  final pdfController = TPdfController(
    // showScrollbar: TPlatform.isDesktop,
    // customPdfPageFooterWidget: (context, pageIndex) => TCustomPageFooterWidget(
    //   basefooterHeight: 50,
    //   child: Center(child: Text('Page: $pageIndex')),
    // ),
    // customScrollbar: (context, pageIndex) =>
    //     TCustomScrollbarWidget.ui3(pageIndex),
    // pageFooterWidget: (page) => Text('I am Footer: $page'),
  );

  void init() {
    pdfController.onPdfLoaded.listen((event) {
      print('Pdf Loaded Time: ${event.elapsed.autoTimeLabel()}');
      showTSnackBar(
        context,
        'Loaded Time: ${event.elapsed.autoTimeLabel()}',
        showCloseIcon: true,
      );
      //page: 11 - offsetX: -0.8081921947733832-zoom: 0.8124003868943545
      // pdfController.jumpToPage(
      //   300,
      //   offsetX: -14.8081921947733832,
      //   zoom: 2.8124003868943545,
      // );
    });
    pdfController.onPageChanged.listen((event) {
      print(
        'page: ${event.page} - offsetX: ${pdfController.currentOffsetX}-zoom: ${pdfController.currentZoom}',
      );
    });
    // pdfController.pdfReaderEvent.listen((event) {
    //   if (event is PdfOnLoaded) {
    //     print('Pdf Loaded Time: ${event.loadedElapsedTime.inMilliseconds} ms');
    //     // pdfController.setZoom(1.25);
    //     // 37.83990478515625
    //     // pdfController.jumpToPage(809);
    //     // pdfController.setOffsetX(-125.8132934570312, 2.7);

    //     showTSnackBar(
    //       context,
    //       "Loaded Time: ${event.loadedElapsedTime.getAutoTimeLabel()}",
    //       showCloseIcon: true,
    //     );
    //   }
    //   // if (event is PdfScreenSizeChanged) {
    //   //   print('size changed-maxWidth: ${event.maxWidth}');
    //   // }
    //   if (event is PdfZoomChanged) {
    //     print('zoom: ${pdfController.currentZoom}');
    //   }
    //   if (event is PdfScreenOffsetXChanged) {
    //     print('dev user');
    //     print('screen offset x: ${event.offsetX}');
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        appBar: isFullscreen
            ? null
            : AppBar(title: Text(widget.path.split('/').last)),
        body: Stack(
          children: [
            Positioned.fill(
              left: 0,
              right: 0,
              bottom: 0,
              top: isFullscreen ? 0 : 40,
              child: ClipRRect(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.white,
                    isDarkMode ? BlendMode.difference : BlendMode.dst,
                  ),
                  child: GestureDetector(
                    onDoubleTap: () {
                      if (!isFullscreen) return;
                      isFullscreen = false;
                      setState(() {});
                      ThanPkg.platform.toggleFullScreen(isFullScreen: false);
                    },
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                      child: TPdfReader(
                        path: widget.path,
                        controller: pdfController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isFullscreen)
              Positioned(left: 0, right: 0, top: 0, child: _header),
          ],
        ),
      ),
    );
  }

  Widget get _header => Theme(
    data: isDarkMode ? ThemeData.dark() : ThemeData.light(),
    child: Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 6,
            children: [
              SizedBox(width: 10),
              InkWell(
                mouseCursor: SystemMouseCursors.click,
                onTap: _showGoToPageDialog,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: StreamBuilder(
                    stream: pdfController.onPageChanged,
                    builder: (context, snapshot) {
                      return Text(
                        '${pdfController.currentPage}/${pdfController.totalPage}',
                        style: TextStyle(color: Colors.teal),
                      );
                    },
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    isDarkMode = !isDarkMode;
                  });
                },
                icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
              ),
              StreamBuilder(
                stream: pdfController.onZoomChanged,
                builder: (context, asyncSnapshot) {
                  return Text(
                    'Zoom: ${(pdfController.currentZoom * 100).toInt()}%',
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.zoom_out),
                onPressed: pdfController.zoomOut, // ၂၅% လျှော့မယ်
              ),
              IconButton(
                icon: Icon(Icons.zoom_in),
                onPressed: pdfController.zoomIn, // ၂၅% တိုးမယ်
              ),
              IconButton(
                onPressed: () {
                  isFullscreen = !isFullscreen;
                  ThanPkg.platform.toggleFullScreen(isFullScreen: isFullscreen);
                  setState(() {});
                },
                icon: Icon(
                  isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                ),
              ),
              // ListenableBuilder(
              //   listenable: pdfController,
              //   builder: (context, child) => IconButton(
              //     onPressed: () {
              //       pdfController.setOffsetXAutoLockedEnable(
              //         !pdfController.isOffsetXLocked,
              //       );
              //       pdfController.setOffsetXLocked(
              //         !pdfController.isOffsetXLocked,
              //       );
              //     },
              //     icon: Icon(
              //       pdfController.isOffsetXLocked
              //           ? Icons.lock
              //           : Icons.lock_open,
              //     ),
              //   ),
              // ),
              // scrollbar
              ValueListenableBuilder(
                valueListenable: pdfController.scrollbarNotifier,
                builder: (context, enable, child) {
                  return IconButton(
                    onPressed: () {
                      pdfController.setScrollbarEnable(!enable);
                    },
                    icon: Icon(
                      enable ? Icons.unfold_less : Icons.unfold_more_rounded,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _showGoToPageDialog() {
    showTReanmeDialog(
      context,
      text: pdfController.currentPage.toString(),
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputType: TextInputType.number,
      submitText: 'Go To Page',
      onCheckIsError: (text) {
        final number = int.tryParse(text);
        if (number == null) return 'Page Number is Required!';
        if (number > pdfController.totalPage) {
          return 'Page: `$number` > Total: `${pdfController.totalPage}`';
        }
        return null;
      },
      onSubmit: (text) {
        pdfController.jumpToPage(int.parse(text));
      },
    );
  }
}
