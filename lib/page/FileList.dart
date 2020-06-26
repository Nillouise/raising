import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/exception/SmbException.dart';
import 'package:raising/model/file_info.dart';
import 'package:raising/model/smb_list_model.dart';
import 'package:raising/model/smb_navigation.dart';
import 'package:raising/page/viewer.dart';

import 'drawer.dart';
import 'package:permission_handler/permission_handler.dart';

var logger = Logger();

class FileList extends StatefulWidget {
  FileList({Key key}) : super(key: key);

  @override
  FileListState createState() {
    return FileListState();
  }
}

void test() async {
  var smb = Smb();
  await smb.test();
}

class FileListState extends State<FileList> {
  void test() async {
    var smb = Smb();
    await smb.test();
  }

  @override
  Widget build(BuildContext context) {
    SmbListModel listModel = Provider.of<SmbListModel>(context);
    if (listModel.smbs.length == 0) {
      return Center(
          child: GestureDetector(
            child: Row(
//          crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.settings),
                const Text('添加Smb链接'),
              ],
            ),
            onTap: () {
              showDialog(context: context, child: SmbManage());
            },
          ));

      return Center();
    } else {
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
              // 请求成功，显示数据
              return Center(
                  child: ListView.builder(
                    itemCount: snapshot.data.files.length,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    itemBuilder: (context, index) {
                      SmbListModel b = Provider.of<SmbListModel>(context);
                      SmbNavigation catalog = Provider.of<SmbNavigation>(
                          context);

                      List<FileInfo> files = catalog.files;
                      return ListTile(
                        title: Text(files[index].filename),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
//                              Viewer(files[index].absPath,0,index: 0,),
                                FutureViewerChecker(0, files[index].absPath)
                            ),
                          );
                        },
                      );
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
}
