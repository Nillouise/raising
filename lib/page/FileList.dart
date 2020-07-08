import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/model/file_info.dart';
import 'package:raising/model/smb_list_model.dart';
import 'package:raising/model/smb_navigation.dart';
import 'package:raising/page/viewer.dart';

import 'drawer.dart';

var logger = Logger();

class Explorer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ExplorerState();
  }
}

class ExplorerState extends State<Explorer> {
  String _dirname(String path) {
    var dirname = p.dirname(path);
    return dirname == '.' ? "" : dirname;
  }

  @override
  Widget build(BuildContext context) {
    SmbNavigation catalog = Provider.of<SmbNavigation>(context);

    return new WillPopScope(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[Text("path:" + (catalog.path ?? ""))],
            ),
            Expanded(
              child: FileList(),
            )
          ],
        ),
        onWillPop: () async {
          SmbNavigation catalog =
              Provider.of<SmbNavigation>(context, listen: false);
          if (p.rootPrefix(catalog.path) == catalog.path) {
            return true;
          } else {
            var smb = Smb.getCurrentSmb();
            catalog.refresh(context, _dirname(catalog.path), smb.id);
            return false;
          }
        });
  }
}

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
    SmbNavigation catalog = Provider.of<SmbNavigation>(context);
    if (listModel.smbs.length == 0) {
      //处理没有smb的情况
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
    } else if (catalog.smbId?.isEmpty ?? true) {
      //处理没选SMB的情况
      SmbListModel smbListModel = Provider.of<SmbListModel>(context);
      return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: smbListModel.smbs.length,
          itemBuilder: (context, index) {
            final item = smbListModel.smbs[index];

            return Dismissible(
              // Each Dismissible must contain a Key. Keys allow Flutter to
              // uniquely identify widgets.
              key: Key(item.id),
              // Provide a function that tells the app
              // what to do after an item has been swiped away.
              onDismissed: (direction) {
                // Remove the item from the data source.
                setState(() {
                  smbListModel.removeSmb(item.id);
                });
                // Then show a snackbar.
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text("$item dismissed")));
              },
              // Show a red background as the item is swiped away.
              background: Container(color: Colors.red),
              child: ListTile(
                title: Text('${item.id}'),
                onTap: () {
                  SmbListModel smbListModel =
                      Provider.of<SmbListModel>(context, listen: false);
                  var smb = smbListModel.smbById(item.id);
                  smb.init();
                  SmbNavigation smbNavigation =
                      Provider.of<SmbNavigation>(context, listen: false);
                  smbNavigation.refresh(context, smb.path, item.id);
//                smbListModel.
//                Smb.pushConfig(item.id, hostname, shareName, domain, username, password, path, searchPattern)
                },
              ),
            );
          });
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
                  SmbNavigation catalog = Provider.of<SmbNavigation>(context);

                  List<FileInfo> files = catalog.files;
                  return ListTile(
                    title: Text(files[index].filename),
                    onTap: () {
                      if (files[index].isDirectory) {
                        var smb = Smb.getCurrentSmb();
                        SmbNavigation smbNavigation =
                            Provider.of<SmbNavigation>(context, listen: false);
                        smbNavigation.refresh(
                            context,
                            p.join(smbNavigation.path, files[index].filename),
                            smb.id);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
//                              Viewer(files[index].absPath,0,index: 0,),
                                  FutureViewerChecker(0, files[index].absPath)),
                        );
                      }
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
