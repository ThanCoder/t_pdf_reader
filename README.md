# T Pdf Reader

A lightweight and high-performance PDF reader for Flutter, powered by `than_pdf_engine`. Optimized for handling large-sized PDF files efficiently. While it focuses on core rendering performance, it offers a modular architecture that allows developers to easily extend or implement advanced features as needed.

### **Supported Platforms**

- **Android**
- **Linux**

### **Key Features**

- **High Performance:** Specifically optimized to handle large PDF files without memory issues.
- **Modular Design:** Built with a simple core, allowing you to implement your own features (annotations, text selection, etc.) on top of the engine.

> **Note:** This package is currently in its early stages. It provides essential rendering capabilities but is less feature-rich compared to alternatives like `pdfrx`. You are encouraged to extend its functionality to fit your specific requirements.

### **Example Usage**

```dart
final pdfController = TPdfController();

TPdfReader(
  path: widget.path,
  password: null,
  controller: pdfController,
),
```

### Example File

[Go Full Example](#full-example)

[Check out the implementation details here](https://github.com/ThanCoder/t_pdf_reader/blob/main/example/lib/reader_v2.dart)

### Custom Scroll Widgets

```dart
late final TPdfController pdfController;
pdfController = TPdfController(
      scrollbarWidget: (thumbWidth, thumbHeight) => defaultScrollbar1(thumbWidth: thumbWidth, thumbHeight: thumbHeight),
);

// default custom scrollbar

//defaultScrollbar1
//defaultScrollbarMinimal
//defaultScrollbarNeon
```

### Footer Widget

```dart
late final TPdfController pdfController;
pdfController = TPdfController(
      pageFooterWidget: (page) => Text('I am Footer: $page'),
);
```

### Controller Events

```dart
late final TPdfController pdfController;
pdfController = TPdfController();

pdfController.onPdfLoaded.listen((event) {
  print('Pdf Loaded Time: ${event.elapsed.autoTimeLabel()}');
  showTSnackBar(
    context,
    'Loaded Time: ${event.elapsed.autoTimeLabel()}',
    showCloseIcon: true,
  );
  // page: 11 - offsetX: -0.8081921947733832-zoom: 0.8124003868943545
  pdfController.jumpToPage(
    11,
    offsetX: -14.8081921947733832, //recent offsetx
    zoom: 2.8124003868943545, //recent zoom
  );
});
pdfController.onPageChanged.listen((event) {
  print(
    'page: ${event.page} - offsetX: ${pdfController.currentOffsetX}-zoom: ${pdfController.currentZoom}',
  );
});
```

### Key Events

```dart
late final TPdfController pdfController;
pdfController = TPdfController(
  onKeyEvent: (node, event) {
    if (event is KeyDownEvent && event.logicalKey == .escape) {
      if (isFullscreen) {
        isFullscreen = false;
        setState(() {});
        ThanPkg.platform.toggleFullScreen(isFullScreen: isFullscreen);
      }
      return .handled;
    }
    if (event is KeyDownEvent && event.physicalKey == .keyF) {
      isFullscreen = !isFullscreen;
      setState(() {});
      ThanPkg.platform.toggleFullScreen(isFullScreen: isFullscreen);
      return .handled;
    }
    return .ignored;
  },
);
```

### Full Example

<details>
  <summary>Click Expand</summary>
  
```dart
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
  late final TPdfController pdfController;
  @override
  void initState() {
    pdfController = TPdfController(
      scrollbarWidget: (thumbWidth, thumbHeight) => defaultScrollbarNeon(
        thumbWidth: thumbWidth,
        thumbHeight: thumbHeight,
      ),
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == .escape) {
          if (isFullscreen) {
            isFullscreen = false;
            setState(() {});
            ThanPkg.platform.toggleFullScreen(isFullScreen: isFullscreen);
          }
          return .handled;
        }
        if (event is KeyDownEvent && event.physicalKey == .keyF) {
          isFullscreen = !isFullscreen;
          setState(() {});
          ThanPkg.platform.toggleFullScreen(isFullScreen: isFullscreen);
          return .handled;
        }
        return .ignored;
      },
    );
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

  void init() {
    pdfController.onPdfLoaded.listen((event) {
      print('Pdf Loaded Time: ${event.elapsed.autoTimeLabel()}');
      showTSnackBar(
        context,
        'Loaded Time: ${event.elapsed.autoTimeLabel()}',
        showCloseIcon: true,
      );
      // page: 11 - offsetX: -0.8081921947733832-zoom: 0.8124003868943545
      pdfController.jumpToPage(
        300,
        offsetX: -14.8081921947733832,
        zoom: 2.8124003868943545,
      );
    });
    pdfController.onPageChanged.listen((event) {
      print(
        'page: ${event.page} - offsetX: ${pdfController.currentOffsetX}-zoom: ${pdfController.currentZoom}',
      );
    });
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

```

</details>


