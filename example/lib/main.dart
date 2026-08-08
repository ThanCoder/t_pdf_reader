import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:t_pdf_reader_example/reader_v2.dart';
import 'package:t_pdf_reader_example/thumb_page.dart';
import 'package:than_pkg/than_pkg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TWidgets.instance.

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MyApp(),
      theme: ThemeData.dark(),
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

  final dir = Directory('/home/thancoder/Documents/pdf');

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
    return Center(
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
          routeWidget(
            '/home/thancoder/Documents/pdf/တာတေ၊_မဖဲဝါကိုကိုက်တဲတစ္ဆေ.pdf',
          ),
          routeWidget('/home/thancoder/Documents/pdf/test2.pdf'),
          routeWidget('/home/thancoder/Documents/pdf/test.pdf'),
          routeWidget('/home/thancoder/Documents/Telegram Desktop/test2.pdf'),
          routeWidget('/home/thancoder/Documents/Telegram Desktop/test3.pdf'),
          routeWidget('/storage/emulated/0/test.pdf'),
        ],
      ),
    );
  }

  Widget routeWidget(String path) {
    final name = path.split('/').last;
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReaderV2(path: path)),
        );
      },
      child: Text(name),
    );
  }

  Future<void> goReader(String path) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderV2(path: path)),
    );
  }
}
