import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:t_pdf_reader_example/reader_v2.dart';
import 'package:than_pkg/than_pkg.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MyApp(),
      // theme: ThemeData.dark(),
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
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderV2(
                    path:
                        '/home/thancoder/Documents/Telegram Desktop/လူသတ်ကုန်းကမဖဲဝါ၊တာတေ.pdf',
                  ),
                ),
              );
            },
            child: Text('လူသတ်ကုန်းကမဖဲဝါ၊တာတေ'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderV2(
                    path: '/home/thancoder/Documents/Telegram Desktop/test.pdf',
                  ),
                ),
              );
            },
            child: Text('Small Pdf'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderV2(
                    path:
                        '/home/thancoder/Documents/Telegram Desktop/test2.pdf',
                  ),
                ),
              );
            },
            child: Text('Big Pdf'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReaderV2(
                    path:
                        '/home/thancoder/Documents/Telegram Desktop/test3.pdf',
                  ),
                ),
              );
            },
            child: Text('Very Big Pdf'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReaderV2(path: '/storage/emulated/0/test.pdf'),
                ),
              );
            },
            child: Text('Android Small Pdf'),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ReaderV2(path: '/storage/emulated/0/test2.pdf'),
                ),
              );
            },
            child: Text('Android Big Pdf'),
          ),
        ],
      ),
    );
  }

  Future<void> goReader(String path) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReaderV2(path: path)),
    );
  }
}
