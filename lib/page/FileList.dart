import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:popup_menu/popup_menu.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/constant/Constant.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/image/ExploreCO.dart';
import 'package:raising/image/ExploreFile.dart';
import 'package:raising/image/ExtractCO.dart';
import 'package:raising/image/WholeFileContentCO.dart';
import 'package:raising/model/ExploreNavigator.dart';
import 'package:raising/model/HostModel.dart';
import 'package:raising/model/smb_list_model.dart';
import 'package:raising/model/smb_navigation.dart';
import 'package:raising/page/searchPage.dart';
import 'package:raising/page/viewer.dart';

import '../util.dart';
import 'common_widget/LoadingWidget.dart';
import 'drawer.dart';

var logger = Logger();

//此类还没重构完成
class PathAndSearch extends StatefulWidget {
  final String path;

  PathAndSearch(this.path);

  @override
  State<StatefulWidget> createState() {
    return PathAndSearchState();
  }
}

class PathAndSearchState extends State<PathAndSearch> {
  void showPopup(Offset offset) {
    PopupMenu menu = PopupMenu(
      // backgroundColor: Colors.teal,
      // lineColor: Colors.tealAccent,
      maxColumn: 3,
      items: [
        // MenuItem(title: 'Copy', image: Image.asset('assets/copy.png')),
        // MenuItem(title: 'Home', image: Icon(Icons.home, color: Colors.white,)),
        MenuItem(
            title: 'Mail',
            image: Icon(
              Icons.mail,
              color: Colors.white,
            )),
        MenuItem(
            title: 'Power',
            image: Icon(
              Icons.power,
              color: Colors.white,
            )),
        MenuItem(
            title: 'Setting',
            image: Icon(
              Icons.settings,
              color: Colors.white,
            )),
        MenuItem(
            title: 'PopupMenu',
            image: Icon(
              Icons.menu,
              color: Colors.white,
            ))
      ],
    );
    menu.show(rect: Rect.fromPoints(offset, offset));
  }

  @override
  Widget build(BuildContext context) {
    PopupMenu.context = context;
    return Row(
      children: <Widget>[
        Expanded(child: Text("${widget.path ?? ""}")),
//        new Icon(
//          Icons.star,
//          color: Colors.red[500],
//        ),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchPage()),
            );
          },
          child: Icon(Icons.search),
        ),
        InkWell(
          onTapDown: (TapDownDetails details) {
            showPopup(details.globalPosition);
//            print('fff');
          },
          onTap: () {
            print('ok');
          },
          child: Icon(Icons.sort),
        ),
      ],
    );
  }
}

class ExplorerWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ExplorerWidgetState();
  }
}

class ExplorerWidgetState extends State<ExplorerWidget>
    with AutomaticKeepAliveClientMixin<ExplorerWidget> {
  String _dirname(String path) {
    var dirname = p.dirname(path);
    return dirname == '.' ? "" : dirname;
  }

  @override
  Widget build(BuildContext context) {
    ExploreNavigator catalog = Provider.of<ExploreNavigator>(context);

    return new WillPopScope(
        child: Column(
          children: <Widget>[
            PathAndSearch("path:${catalog.title ?? ""}"),
            Expanded(
              child: FileList(),
            )
          ],
        ),
        onWillPop: () async {
          //退出应用
          ExploreNavigator catalog =
              Provider.of<ExploreNavigator>(context, listen: false);
          if (catalog.isRoot()) {
            return true;
          } else {
            //返回上一级目录
            catalog.refreshPath(_dirname(catalog.absPath));
            return false;
          }
        });
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class FileList extends StatefulWidget {
  FileList({Key key}) : super(key: key);

  @override
  FileListState createState() {
    return FileListState();
  }
}

class FileListState extends State<FileList> {
  double _pixels;
  int _timestamp = 0;

  @override
  Widget build(BuildContext context) {
    SmbListModel listModel = Provider.of<SmbListModel>(context);
    HostModel hostModel = Provider.of<HostModel>(context);
    ExploreNavigator catalog = Provider.of<ExploreNavigator>(context);
    if (hostModel.hosts.length == 0) {
      //处理没有配置任何一个host的情况
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
          showDialog(context: context, child: HostManage());
        },
      ));
    } else if (!catalog.isSelectHost()) {
      //处理没选host的情况
      return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: hostModel.hosts.length,
          itemBuilder: (context, index) {
            final item = hostModel.hosts[index];

            return Dismissible(
              // Each Dismissible must contain a Key. Keys allow Flutter to
              // uniquely identify widgets.
              key: Key(item.id),
              // Provide a function that tells the app
              // what to do after an item has been swiped away.
              onDismissed: (direction) {
                // Remove the item from the data source.
                setState(() {
                  hostModel.remove(index);
                });
                // Then show a snackbar.
                Scaffold.of(context)
                    .showSnackBar(SnackBar(content: Text("$item dismissed")));
              },
              // Show a red background as the item is swiped away.
              background: Container(color: Colors.red),
              child: ListTile(
                title: Text('${item.nickName}'),
                onTap: () {
                  WebdavExploreFile webdavExploreFile = WebdavExploreFile(item);
                  SmbChannel.explorefiles = [webdavExploreFile];
                  catalog.refresh(webdavExploreFile, "");
                },
              ),
            );
          });
    } else {
      return FutureBuilder<bool>(
        future: () async {
          ExploreNavigator catalog =
              Provider.of<ExploreNavigator>(context, listen: false);
          await catalog.awaitQueryFiles();

          return true;
        }(),
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          // 请求已结束
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              // 请求失败，显示错误
              return Text("Error: ${snapshot.error}");
            } else {
              ExploreNavigator catalog =
                  Provider.of<ExploreNavigator>(context, listen: false);
              // 请求成功，显示数据
              return Center(
                  child: NotificationListener<ScrollNotification>(
                      onNotification: (scrollNotification) {
                        //这里的逻辑其实用不着，但目前就先不删了
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
                        itemCount: catalog.files.length,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        itemBuilder: (context, index) {
                          List<ExploreCO> files = catalog.files;
                          return ListTile(
                            leading: AspectRatio(
                                aspectRatio: 1,
                                child: PreviewFile(files[index].absPath,
                                    files[index], catalog)),
                            title: Text(files[index].filename),
                            onTap: () {
                              if (files[index].isDirectory) {
                                catalog.refreshPath(Utils.joinPath(
                                    catalog.absPath, files[index].filename));
                              } else if (Constants.COMPRESS_AND_IMAGE_FILE
                                  .contains(
                                      p.extension(files[index].filename))) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FutureViewerChecker(
                                          0, files[index].absPath, catalog)),
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

/**
 * 应该改成先返回缓存的内容，然后后台查询真正的图，再替换。
 */
class PreviewFile extends StatelessWidget {
  final String absPath;
  final ExploreCO fileinfo;
  final ExploreNavigator exploreNavigator;

  PreviewFile(this.absPath, this.fileinfo, this.exploreNavigator);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(future: () async {
      if (fileinfo.isDirectory) {
        return Icon(Icons.folder);
      } else if ((Constants.COMPRESS_AND_IMAGE_FILE)
          .contains((p.extension(fileinfo.filename)))) {
        if (Utils.isCompressFile(fileinfo.filename)) {
          ExtractCO content = await exploreNavigator.exploreFile
              .loadFileFromZip(absPath, 0, fileSize: fileinfo.size);
          return Image.memory(content.indexContent[0]);
        } else {
          WholeFileContentCO content =
              await exploreNavigator.exploreFile.loadWholeFile(absPath);
          return Image.memory(content.content);
        }
      } else {
        return Icon(Icons.folder_open);
      }
    }(), builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasError) {
          logger.e(snapshot.error);
          return Icon(Icons.error);
        } else {
          return snapshot.data;
        }
      } else {
        return Center(child: LoadingWidget());
      }
    });
  }
}

class ThumbnailFile extends StatelessWidget {
  final FileInfoPO fileinfo;
  final SmbVO _smb;

  ThumbnailFile(this.fileinfo, this._smb);

  @override
  Widget build(BuildContext context) {
    SmbVO smbVO = _smb.copy();
    smbVO.absPath = Utils.joinPath(smbVO.absPath, fileinfo.filename);

    return FutureBuilder<Widget>(future: () async {
      if (fileinfo.isDirectory) {
        return Icon(Icons.folder);
      } else if ((Constants.COMPRESS_AND_IMAGE_FILE)
          .contains((p.extension(fileinfo.filename)))) {
        FileContentCO content;
        if (Utils.isCompressFile(fileinfo.filename)) {
          content = await Utils.getFileFromZip(0, smbVO);
        } else {
          content = await Utils.getWholeFile(smbVO);
        }
        return Image.memory(content.content, errorBuilder:
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
        return Center(child: Icon(Icons.check_box_outline_blank));
      }
    });
  }
}
