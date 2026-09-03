import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:t_pdf_reader_example/my_reader.dart';
import 'package:t_pdf_reader_example/thumb_page.dart';
import 'package:than_pkg/than_pkg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TWidgets.instance.

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MyApp(),
      theme: ThemeData.light(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool dropEnable = true;

  final dir = Directory('/home/thancoder/Documents/PDF');
  List<String> files = [];
  @override
  void initState() {
    super.initState();
    for (var f in dir.listSync()) {
      if (!f.path.endsWith('.pdf')) continue;
      files.add(f.path);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DropTarget(
        enable: dropEnable,
        onDragDone: (details) async {
          if (details.files.isEmpty) return;
          final file = details.files.first;
          if (!file.path.endsWith('.pdf')) return;
          setState(() {
            dropEnable = false;
          });
          await goReader(file.path);
          setState(() {
            dropEnable = true;
          });
        },
        child: bodyWidget,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            if (!await ThanPkg.platform.isStoragePermissionGranted()) {
              await ThanPkg.platform.requestStoragePermission();
            }
            // await TPdfCoreThumbnailer.extractImageAndSave(
            //   pageIndex: 1,
            //   '/home/thancoder/Documents/pdf/test2.pdf',
            //   savePath: 'out.png',
            //   overrideExistsImage: true,
            // );
          } catch (e) {
            debugPrint(e.toString());
          }
        },
      ),
    );
  }

  Widget get bodyWidget {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              title: Text('Thumbnail Gen'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ThumbPage(dir: dir)),
                );
              },
            ),
            ...files.map((e) => routeWidget(e)),
          ],
        ),
      ),
    );
  }

  Widget routeWidget(String path) {
    final name = path.split('/').last;
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyReader(path: path)),
        );
      },
      child: Text(name),
    );
  }

  Future<void> goReader(String path) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyReader(path: path)),
    );
  }
}
