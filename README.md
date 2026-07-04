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
[Check out the implementation details here](https://github.com/ThanCoder/t_pdf_reader/blob/main/example/lib/reader_v2.dart)
