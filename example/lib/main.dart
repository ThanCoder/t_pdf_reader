import 'package:flutter/material.dart';
import 'package:t_pdf_reader_example/reader.dart';
import 'package:than_pkg/than_pkg.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fullscreen ဖြစ်အောင် status bar နဲ့ navigation bar ကို ဖျောက်တာပါ
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: const MyApp()));
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
                    builder: (context) =>
                        Reader(path: '/home/thancoder/Documents/test.pdf'),
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
                    builder: (context) =>
                        Reader(path: '/home/thancoder/Documents/test2.pdf'),
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
                    builder: (context) =>
                        Reader(path: '/storage/emulated/0/test.pdf'),
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
                        Reader(path: '/storage/emulated/0/test2.pdf'),
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
            //   '/home/thancoder/Documents/test2.pdf',
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
