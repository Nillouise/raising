import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/model/smb_list_model.dart';
import 'package:raising/model/smb_navigation.dart';

class FileList extends StatefulWidget {
  FileList({Key key}) : super(key: key);

  @override
  FileListState createState() {
    return FileListState();
  }
}

class FileListState extends State<FileList> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SmbNavigation>(
      future: () {
        SmbNavigation catalog = Provider.of<SmbNavigation>(context);
        return catalog.awaitSelf();
      }(),
      builder: (BuildContext context, AsyncSnapshot<SmbNavigation> snapshot) {
        // 请求已结束
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return Text("Error: ${snapshot.error}");
          } else {
            // 请求成功，显示数据s
            return Center(
                child: ListView.builder(
              itemCount: snapshot.data.files.length,
              padding: const EdgeInsets.symmetric(vertical: 18),
              itemBuilder: (context, index) {
                SmbListModel b = Provider.of<SmbListModel>(context);
                SmbNavigation catalog = Provider.of<SmbNavigation>(context);

                List<FileInfo> files = catalog.files;
                return ListTile(title: Text(files[index].filename + "1"));
              },
            ));
          }
        } else {
          // 请求未结束，显示loading
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
