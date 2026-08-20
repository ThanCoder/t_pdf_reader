# T PDF Reader

A customizable PDF reader widget for Flutter, designed for smooth document viewing with programmatic control, zooming, page navigation, custom UI components, scrollbar customization, and image caching.

## Features

* 📄 PDF document rendering
* 🔍 Zoom in / zoom out
* 🎯 Fit-to-view zoom
* 📖 Jump to a specific page
* 🖱️ Mouse wheel and pointer scrolling
* 👆 Touch scrolling and pinch-to-zoom
* 🖥️ Desktop-friendly interaction
* 📱 Mobile gesture support
* 🎨 Custom footer widgets
* 📜 Fully customizable scrollbar
* 🌙 Custom dark-mode support
* 🖼️ Image cache state listeners
* 🔄 Reactive controller streams
* ⚡ Programmatic reader actions
* 🧩 Extensible reader UI

---



## Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';

class MyReader extends StatefulWidget {
  const MyReader({
    super.key,
    required this.path,
  });

  final String path;

  @override
  State<MyReader> createState() => _MyReaderState();
}

class _MyReaderState extends State<MyReader> {
  final controller = TPdfController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TPdfReader(
        path: widget.path,
        controller: controller,
      ),
    );
  }
}
```

---

# Controller

`TPdfController` provides access to reader state, actions, and streams.

```dart
final controller = TPdfController();
```

The controller can be used to:

* Control zoom
* Navigate between pages
* Listen for reader events
* Access the current reader state
* Customize reader widgets
* Control scrollbar visibility
* Monitor image cache state

---

# Reader Actions

## Fit Zoom

Automatically fit the PDF to the available viewport.

```dart
controller.action.setFitZoom();
```

## Zoom In

```dart
controller.action.zoomIn();
```

## Zoom Out

```dart
controller.action.zoomOut();
```

## Set Zoom

```dart
controller.action.setZoom(1.5);
```

## Jump to Page

```dart
controller.action.jumpPage(100);
```

---

# Reader State

The current reader state is available through the controller.

```dart
final zoom = controller.state.zoom;
final page = controller.state.currentPage;
```

For example:

```dart
controller.stream.zoomChanged.listen((_) {
  print('Zoom: ${controller.state.zoom}');
});
```

---

# Reader Streams

The controller exposes reactive streams for reader state changes.

## Ready

```dart
controller.stream.ready.listen((_) {
  print('PDF reader is ready');
});
```

## Zoom Changed

```dart
controller.stream.zoomChanged.listen((_) {
  print('Zoom: ${controller.state.zoom}');
});
```

## Attached

The `attached` stream can be used to detect when the reader controller is attached to a `TPdfReader`.

```dart
controller.attached.listen((_) {
  print('Reader attached');
});
```

---

# Custom Reader Widgets

`TPdfController` supports custom reader UI through `TPdfWidgetBuilder`.

```dart
final controller = TPdfController(
  widgetBuilder: TPdfWidgetBuilder(
    footerBuilder: (context, page) {
      return Text(
        'Page: $page',
      );
    },
  ),
);
```

This allows applications to customize parts of the reader without modifying the reader itself.

---

# Custom Footer

You can provide your own footer widget using `footerBuilder`.

```dart
final controller = TPdfController(
  widgetBuilder: TPdfWidgetBuilder(
    footerBuilder: (context, page) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Page: $page',
        ),
      );
    },
  ),
);
```

The `page` parameter represents the current page index.

---

# Custom Scrollbar

The scrollbar can be completely customized using `scrollbarBuilder`.

```dart
final controller = TPdfController(
  widgetBuilder: TPdfWidgetBuilder(
    scrollbarBuilder: (context, page) {
      return .new(
        widgetInfo: .new(
          thumbWidth: 20,
          thumbHeight: 40,
        ),
        builder: defaultScrollbarGlow(
          thumbWidth: 20,
          thumbHeight: 40,
        ),
      );
    },
  ),
);
```

The scrollbar builder receives the current page, allowing the scrollbar to also be used as a page indicator.

---

# Custom Scrollbar UI

You can create any Flutter widget for the scrollbar.

```dart
scrollbarBuilder: (context, page) {
  final colorScheme = Theme.of(context).colorScheme;

  return .new(
    widgetInfo: .new(
      thumbWidth: 32,
      thumbHeight: 28,
      positionRight: 12,
    ),
    builder: DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Center(
        child: Text(
          '${page + 1}',
          style: TextStyle(
            color: colorScheme.onPrimaryContainer,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ),
  );
},
```

This makes it possible to build:

* Minimal scrollbars
* Rounded scrollbars
* Neon scrollbars
* Glass-style scrollbars
* Page indicator scrollbars
* Custom branded scrollbars

---

# Built-in Scrollbar Styles

Built-in scrollbar styles can be used directly.

```dart
builder: defaultScrollbarGlow(
  thumbWidth: 20,
  thumbHeight: 40,
),
```

Example:

```dart
scrollbarBuilder: (context, page) {
  return .new(
    widgetInfo: .new(
      thumbWidth: 20,
      thumbHeight: 40,
    ),
    builder: defaultScrollbarGlow(
      thumbWidth: 20,
      thumbHeight: 40,
    ),
  );
},
```

---

# Scrollbar Toggle

The scrollbar visibility can be controlled from the UI.

```dart
PdfScrollbarToggler(
  controller: controller,
)
```

This is useful for applications that want to provide a reader toolbar with a scrollbar visibility toggle.

---

# Page Navigation

A page listener can be used to display the current page and trigger page navigation.

```dart
PdfPageListener(
  controller: controller,
  onClicked: jumpPage,
)
```

For example:

```dart
void jumpPage() {
  showDialog(
    context: context,
    builder: (context) {
      return PdfPageJumpDialog(
        controller: controller,
      );
    },
  );
}
```

---

# Zoom Controls

Built-in zoom controls can be added to a reader toolbar.

```dart
PdfZoomOut(
  controller: controller,
),

PdfZoomIn(
  controller: controller,
),

PdfZoomListener(
  controller: controller,
),
```

This provides:

* Zoom out button
* Zoom in button
* Current zoom display/listening

---

# Image Cache

The reader exposes image cache events through the controller.

```dart
PdfCacheImageListener(
  controller: controller,
)
```

This can be used to monitor PDF page image caching and provide cache-related UI.

---

# Dark Mode

The reader can be combined with Flutter's `ColorFiltered` widget to create a custom dark reading mode.

```dart
bool darkMode = false;
```

```dart
ColorFiltered(
  colorFilter: ColorFilter.mode(
    Colors.white,
    darkMode
        ? BlendMode.difference
        : BlendMode.dstIn,
  ),
  child: TPdfReader(
    path: widget.path,
    controller: controller,
  ),
)
```

Toggle the mode from the UI:

```dart
IconButton(
  onPressed: () {
    setState(() {
      darkMode = !darkMode;
    });
  },
  icon: Icon(
    darkMode
        ? Icons.dark_mode_outlined
        : Icons.light_mode_outlined,
  ),
)
```

---

# Complete Example

The following example demonstrates a custom reader toolbar, page navigation, zoom controls, dark mode, scrollbar customization, and cache monitoring.

```dart
class MyReader extends StatefulWidget {
  const MyReader({
    super.key,
    required this.path,
  });

  final String path;

  @override
  State<MyReader> createState() => _MyReaderState();
}

class _MyReaderState extends State<MyReader> {
  final controller = TPdfController(
    widgetBuilder: TPdfWidgetBuilder(
      footerBuilder: (context, page) {
        return Text(
          'Page: ${page + 1}',
        );
      },
      scrollbarBuilder: (context, page) {
        return .new(
          widgetInfo: .new(
            thumbWidth: 20,
            thumbHeight: 40,
          ),
          builder: defaultScrollbarGlow(
            thumbWidth: 20,
            thumbHeight: 40,
          ),
        );
      },
    ),
  );

  bool darkMode = false;

  @override
  void initState() {
    super.initState();

    controller.attached.listen((_) {
      controller.stream.ready.listen((_) {
        controller.action.setFitZoom();
      });

      controller.stream.zoomChanged.listen((_) {
        print(
          'zoom: ${controller.state.zoom}',
        );
      });
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Reader'),
      ),
      body: StreamBuilder(
        stream: controller.attached,
        builder: (context, snapshot) {
          return Stack(
            children: [
              Positioned.fill(
                top: 50,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.white,
                    darkMode
                        ? BlendMode.difference
                        : BlendMode.dstIn,
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
                child: _buildToolbar(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          PdfPageListener(
            controller: controller,
            onClicked: jumpPage,
          ),

          PdfZoomOut(
            controller: controller,
          ),

          PdfZoomIn(
            controller: controller,
          ),

          PdfZoomListener(
            controller: controller,
          ),

          IconButton(
            onPressed: () {
              setState(() {
                darkMode = !darkMode;
              });
            },
            icon: Icon(
              darkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
            ),
          ),

          PdfScrollbarToggler(
            controller: controller,
          ),

          PdfCacheImageListener(
            controller: controller,
          ),
        ],
      ),
    );
  }

  void jumpPage() {
    showDialog(
      context: context,
      builder: (context) {
        return PdfPageJumpDialog(
          controller: controller,
        );
      },
    );
  }
}
```

---

# Architecture

The reader is designed around a controller-driven architecture.

```text
TPdfReader
    │
    └── TPdfController
          │
          ├── state
          │
          ├── action
          │
          ├── stream
          │
          └── widgetBuilder
                │
                ├── footerBuilder
                └── scrollbarBuilder
```

This keeps the PDF rendering engine and reader state separate from application-specific UI.

---

# Customization

The reader is intentionally designed to be customizable.

You can build your own:

* Header
* Footer
* Toolbar
* Scrollbar
* Page indicator
* Zoom controls
* Dark-mode controls
* Reader overlays
* Page navigation UI

The default reader UI can be used as-is, or replaced with application-specific widgets.

---

# License

Add your project license information here.
