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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
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
                          '/home/thancoder/Documents/pdf/မပစ်ကြပါနဲ့-Book-1-3.pdf',
                    ),
                  ),
                );
              },
              child: Text('မပစ်ကြပါနဲ့-Book-1-3'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReaderV2(
                      path: '/home/thancoder/Documents/pdf/test.pdf',
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
                      path: '/home/thancoder/Documents/pdf/test2.pdf',
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
                      path: '/home/thancoder/Documents/pdf/test3.pdf',
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
}
