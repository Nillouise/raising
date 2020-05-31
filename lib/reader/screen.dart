import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

Future<Uint8List> getImage(String filename) {
  List<String> lst = List<String>();
  lst.add(filename);
  return Smb.getConfig("[C]").previewFiles(lst).then((res) {
    Uint8List re = res[filename];
    return re;
  });
//  Smb.getConfig("[C]").listZip(filename);
//  return Future.delayed(Duration(seconds: 1));
//  return Smb.getConfig("[C]").getFile(filename).then((bytes) {
//    // Decode the Zip file
//    final archive = ZipDecoder().decodeBytes(bytes);
//
//    // Extract the contents of the Zip archive to disk.
//    for (final file in archive) {
//      final filename = file.name;
//      if (file.isFile) {
//        final data = file.content as Uint8List;
//        return data;
//      }
//    }
//    return null;
//  });
}

class ReaderScreen extends StatefulWidget {
  ReaderScreen({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _ReaderScreenState createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(widget.title),
        ),
        body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Center(
          child: FutureBuilder<Uint8List>(
            future: getImage(widget.title),
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              // 请求已结束
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  // 请求失败，显示错误
                  return Text("Error: ${snapshot.error}");
                } else {
                  // 请求成功，显示数据
                  return Image.memory(snapshot.data);
                }
              } else {
                // 请求未结束，显示loading
                return CircularProgressIndicator();
              }
            },
          ),
        )));
  }
}
