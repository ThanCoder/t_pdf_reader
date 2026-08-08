// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:t_pdf_reader/t_pdf_reader.dart';
import 'package:t_widgets/t_widgets.dart';

class ThumbPage extends StatefulWidget {
  final Directory dir;
  const ThumbPage({super.key, required this.dir});

  @override
  State<ThumbPage> createState() => _ThumbPageState();
}

class _ThumbPageState extends State<ThumbPage> {
  @override
  void initState() {
    outDir = Directory('${widget.dir.path}/thumbs');
    super.initState();
    init();
  }

  ///name , nameonly
  List<(String, String)> list = [];
  late Directory outDir;

  bool isLoading = false;
  final gen = PdfThumbnailGenerator.instance;
  void init() async {
    try {
      list.clear();
      if (!outDir.existsSync()) {
        await outDir.create(recursive: true);
      }

      setState(() {
        isLoading = true;
      });
      for (var file in widget.dir.listSync()) {
        if (file is! File) continue;
        final name = file.path.split('/').last;
        final parts = name.split('.');
        parts.removeLast();
        final nameOnly = parts.join('.');

        if (!name.endsWith('pdf')) continue;
        list.add((file.path, nameOnly));
      }

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thumb')),

      body: GridView.builder(
        itemCount: list.length,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200,
          mainAxisExtent: 120,
        ),
        itemBuilder: (context, index) => itemWidget(list[index]),
      ),
    );
  }

  Widget itemWidget((String, String) args) {
    final (path, nameOnly) = args;
    final outFile = File('${outDir.path}/$nameOnly.png');
    if (!outFile.parent.existsSync()) {
      outFile.parent.createSync(recursive: true);
    }
    // print('genPath: $path');
    return FutureBuilder(
      future: gen.generate(path, outFile.path),
      builder: (context, snapshot) {
        if (snapshot.connectionState == .waiting) {
          return TLoader();
        }
        return Image.file(
          outFile,
          errorBuilder: (context, error, stackTrace) {
            print('error: $error');
            return Icon(Icons.image_not_supported, size: 100);
          },
        );
      },
    );
  }
}
