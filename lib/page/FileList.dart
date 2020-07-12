import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/constant/Constant.dart';
import 'package:raising/model/file_info.dart';
import 'package:raising/model/smb_list_model.dart';
import 'package:raising/model/smb_navigation.dart';
import 'package:raising/page/viewer.dart';

import '../util.dart';
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

  double _pixels;
  int _timestamp = 0;

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
                },
              ),
            );
          });
    }
    else if(catalog.share?.isEmpty??true){
      //处理没选share 的情况
      catalog.listShare(hostIp, username, password);



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
                  child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        SmbNavigation smbNavigation =
                            Provider.of<SmbNavigation>(context, listen: false);
                        double pixels = scrollNotification.metrics.pixels;
                        int timestamp = DateTime.now().millisecondsSinceEpoch;
                        if (timestamp - this._timestamp == 0) {
                          smbNavigation.scroll_speed = 0;
                        } else if (this._pixels != null) {
                          final double velocity = (pixels - this._pixels) /
                              (timestamp - this._timestamp);
                          smbNavigation.scroll_speed = velocity;
                        }
                        this._pixels = pixels;
                        this._timestamp = timestamp;
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: snapshot.data.files.length,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        itemBuilder: (context, index) {
                          SmbListModel b = Provider.of<SmbListModel>(context);
                          SmbNavigation catalog =
                              Provider.of<SmbNavigation>(context);
                          List<FileInfo> files = catalog.files;
                          return ListTile(
                            leading: AspectRatio(
                                aspectRatio: 1,
                                child: PreviewFile(files[index])),
                            title: Text(files[index].filename),
                            onTap: () {
                              if (files[index].isDirectory) {
                                var smb = Smb.getCurrentSmb();
                                SmbNavigation smbNavigation =
                                    Provider.of<SmbNavigation>(context,
                                        listen: false);
                                smbNavigation.refresh(
                                    context,
                                    p.join(smbNavigation.path,
                                        files[index].filename),
                                    smb.id);
                              } else if (Constants.COMPRESS_AND_IMAGE_FILE
                                  .contains(
                                      p.extension(files[index].absPath))) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
//                              Viewer(files[index].absPath,0,index: 0,),
                                          FutureViewerChecker(
                                              0, files[index].absPath)),
                                );
                              }
                            },
                          );
                        },
                      )));
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

class PreviewFile extends StatelessWidget {
  final FileInfo fileinfo;

  PreviewFile(this.fileinfo);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(future: () async {
      if (fileinfo.isDirectory) {
        return Icon(Icons.folder);
      } else if ((Constants.COMPRESS_AND_IMAGE_FILE)
          .contains((p.extension(fileinfo.absPath)))) {
        var smbHalfResult = (await Utils.getPreviewFile(0, fileinfo.absPath));
        return Image.memory(smbHalfResult.result[0].content, errorBuilder:
            (BuildContext context, Object exception, StackTrace stackTrace) {
          return Icon(Icons.error);
        });
      } else {
        return Icon(Icons.folder_open);
      }
    }(), builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasError) {
          return Icon(Icons.error);
        } else {
          return snapshot.data;
        }
      } else {
        return Center(child: CircularProgressIndicator());
      }
    });
  }
}
