import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:popup_menu/popup_menu.dart';
import 'package:provider/provider.dart';
import 'package:raising/constant/Constant.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/image/ExploreCO.dart';
import 'package:raising/image/ExtractCO.dart';
import 'package:raising/image/WholeFileContentCO.dart';
import 'package:raising/image/cache.dart';
import 'package:raising/model/ExploreNavigator.dart';
import 'package:raising/model/HostModel.dart';
import 'package:raising/page/searchPage.dart';
import 'package:raising/page/viewer.dart';

import '../util.dart';
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

class PathBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget child;

  PathBar({
    Key key,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }

  @override
  Size get preferredSize => Size.fromHeight(40.0);
}

class ExplorerWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ExplorerWidgetState();
  }
}

///关于AutomaticKeepAliveClientMixin的作用：https://medium.com/manabie/flutter-simple-cheatsheet-4370a68f98b3
class ExplorerWidgetState extends State<ExplorerWidget> with AutomaticKeepAliveClientMixin<ExplorerWidget> {
  String _dirname(String path) {
    var dirname = p.dirname(path);
    return dirname == '.' ? "" : dirname;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ExploreNavigator catalog = Provider.of<ExploreNavigator>(context);
//    List<String> paths = List.of(["test", "fd", "tetes2", "test3"]);
    List<String> paths = p.split(catalog.relativePath ?? "");

    return new WillPopScope(
        child: Scaffold(
          appBar: AppBar(
            title: PathBar(
              child: Container(
                height: 50,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    itemCount: paths.length,
                    itemBuilder: (BuildContext context, int index) {
                      return InkWell(
                        onTap: () {
                          print(paths[index]);
                          paths.removeRange(index + 1, paths.length);
                          catalog.refreshPath(p.join(catalog.rootPath, p.joinAll(paths)));
//                        setState(() {
//                          path = paths[index];
//                          paths.removeRange(index + 1, paths.length);
//                        });
//                        getFiles();
                        },
                        child: Container(
                          height: 40,
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Text(
                                "${paths[index]}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
//                                  color: index == paths.length - 1 ? Theme.of(context).accentColor : Theme.of(context).textTheme.title.color,
                                  color: Theme.of(context).textTheme.title.color,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) {
                      return Icon(
                        Icons.arrow_forward_ios,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          body: Column(
            children: <Widget>[
              PathAndSearch("path:${catalog.title ?? ""}"),
              Expanded(
                child: FileList(),
              )
            ],
          ),
        ),
        onWillPop: () async {
          //退出应用
          ExploreNavigator catalog = Provider.of<ExploreNavigator>(context, listen: false);
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
  @override
  Widget build(BuildContext context) {
    HostModel hostModel = Provider.of<HostModel>(context);
    ExploreNavigator exploreNavigator = Provider.of<ExploreNavigator>(context);
    if (hostModel.hosts.length == 0) {
      ///处理没有配置任何一个host的情况，即需要加入新的host
      return Center(
          child: GestureDetector(
        child: Row(
//          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.settings),
            const Text('添加Host'),
          ],
        ),
        onTap: () {
          showDialog(context: context, child: HostManage());
        },
      ));
    } else if (!exploreNavigator.isSelectHost()) {
      ///处理没选host的情况，即开始打开host
      return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: hostModel.hosts.length,
          itemBuilder: (context, index) {
            final currentHost = hostModel.hosts[index];
            return Dismissible(
              // Each Dismissible must contain a Key. Keys allow Flutter to
              // uniquely identify widgets.
              key: Key(currentHost.id),
              // Provide a function that tells the app
              // what to do after an item has been swiped away.
              onDismissed: (direction) {
                // Remove the item from the data source.
                setState(() {
                  hostModel.remove(index);
                });
                // Then show a snackbar.
                Scaffold.of(context).showSnackBar(SnackBar(content: Text("$currentHost dismissed")));
              },
              // Show a red background as the item is swiped away.
              background: Container(color: Colors.red),
              child: ListTile(
                title: Text('${currentHost.nickName}'),
                onTap: () {
                  //TODO:这里需要处理选择的是SMB的情况。
                  exploreNavigator.refreshHost(currentHost);
                },
              ),
            );
          });
    } else {
      ///打开文件夹或文件。
      return FileListBuilder();
//      return FutureBuilder<bool>(
//        future: () async {
//          ExploreNavigator catalog = Provider.of<ExploreNavigator>(context, listen: false);
//          await catalog.awaitQueryFiles();
//          return true;
//        }(),
//        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
//          if (snapshot.connectionState == ConnectionState.done) {
//            if (snapshot.hasError) {
//              return Text("Error: ${snapshot.error}");
//            } else {
//              ExploreNavigator exploreNavigator = Provider.of<ExploreNavigator>(context, listen: false);
//              return Center(
//                  child: ListView.builder(
//                itemCount: exploreNavigator.files.length,
//                padding: const EdgeInsets.symmetric(vertical: 18),
//                itemBuilder: (context, index) {
//                  List<ExploreCO> files = exploreNavigator.files;
//                  return ListTile(
//                    leading: AspectRatio(aspectRatio: 1, child: PreviewFile(p.join(exploreNavigator.absPath, files[index].filename), files[index], exploreNavigator)),
//                    title: Text(files[index].filename),
//                    subtitle: Text("1/10"),
//                    onTap: () {
//                      if (files[index].isDirectory) {
//                        exploreNavigator.refreshPath(Utils.joinPath(exploreNavigator.absPath, files[index].filename));
//                      } else if (Constants.COMPRESS_AND_IMAGE_FILE.contains(p.extension(files[index].filename))) {
//                        Navigator.push(
//                          context,
//                          MaterialPageRoute(builder: (context) => FutureViewerChecker(files[index], 0, files[index].absPath, exploreNavigator)),
//                        );
//                      }
//                    },
//                  );
//                },
//              ));
//            }
//          } else {
//            return Center(child: CircularProgressIndicator());
//          }
//        },
//      );
    }
  }
}

class FileListBuilder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: () async {
        ExploreNavigator catalog = Provider.of<ExploreNavigator>(context, listen: false);
        await catalog.awaitQueryFiles();
        return true;
      }(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else {
            ExploreNavigator exploreNavigator = Provider.of<ExploreNavigator>(context, listen: false);
            return Center(
                child: ListView.builder(
              itemCount: exploreNavigator.files.length,
              padding: const EdgeInsets.symmetric(vertical: 18),
              itemBuilder: (context, index) {
                List<ExploreCO> files = exploreNavigator.files;
                return ListTile(
                  leading: AspectRatio(aspectRatio: 1, child: PreviewFile(p.join(exploreNavigator.absPath, files[index].filename), files[index], exploreNavigator)),
                  title: Text(files[index].filename),
                  subtitle: files[index].readInfo == null ? null : Text("${files[index].readInfo.readLength}/${files[index].readInfo.pageLength}"),
                  onTap: () {
                    if (files[index].isDirectory) {
                      exploreNavigator.refreshPath(Utils.joinPath(exploreNavigator.absPath, files[index].filename));
                    } else if (Constants.COMPRESS_AND_IMAGE_FILE.contains(p.extension(files[index].filename))) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FutureViewerChecker(files[index], 0, files[index].absPath, exploreNavigator)),
                      );
                    }
                  },
                );
              },
            ));
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

///TODO:不知道为啥，无法获取获取在memorycache的缓存
class FutureImageProvider extends ImageProvider<FutureImageProvider> {
  final String fileId;
  final Future<Uint8List> Function() getImage;

  FutureImageProvider(this.fileId, this.getImage);

  @override
  ImageStreamCompleter load(FutureImageProvider key, DecoderCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(decode),
      scale: 1.0,
      debugLabel: fileId,
      informationCollector: () sync* {
        yield ErrorDescription('Path: $fileId');
      },
    );
  }

  Future<Codec> _loadAsync(DecoderCallback decode) async {
    final Uint8List bytes = await getImage();

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance?.imageCache?.evict(this);
      throw StateError('$fileId is empty and cannot be loaded as an image.');
    }

    return await decode(bytes);
  }

  @override
  Future<FutureImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FutureImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool res = other is FutureImageProvider && other.fileId == fileId;
    return res;
  }

  @override
  int get hashCode => fileId.hashCode;

  @override
  String toString() => '${objectRuntimeType(this, 'FutureImageProvider')}("$fileId")';
}

/**
 * TODO:应该改成先返回缓存的内容，然后后台查询真正的图，再替换。
 */
class PreviewFile extends StatelessWidget {
  final String absPath; //这个字段应当是能用来请求文件，因为fileinfo 里的信息的absPath可能不准（比如说少路径了，或者加了http://前缀之类）
  final ExploreCO fileinfo;
  final ExploreNavigator exploreNavigator;

  PreviewFile(this.absPath, this.fileinfo, this.exploreNavigator);

  @override
  Widget build(BuildContext context) {
//    FadeInImage(
//      placeholder: CacheImageProvider(exploreNavigator.getFileId(fileinfo)),
//      placeholderErrorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
//        return Icon(Icons.image);
//      },
//      image: FutureImageProvider(exploreNavigator.getFileId(fileinfo), () async {
//        ExtractCO content = await exploreNavigator.exploreFile.loadFileFromZip(absPath, 0, fileSize: fileinfo.size);
//        var thumbNail = content.indexContent[0];
//        exploreNavigator.putThmnailFile(fileinfo, thumbNail);
//        return thumbNail;
//      }),
//    );
    if (fileinfo.isDirectory) {
      return Icon(Icons.folder);
    } else if ((Constants.COMPRESS_AND_IMAGE_FILE).contains((p.extension(fileinfo.filename)))) {
      if (Utils.isCompressFile(fileinfo.filename)) {
//        return FadeInImage(
//          placeholder: CacheImageProvider(exploreNavigator.getFileId(fileinfo)),
//          placeholderErrorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
//            return Icon(Icons.image);
//          },
//          image: FutureImageProvider(exploreNavigator.getFileId(fileinfo), () async {
//            ExtractCO content = await exploreNavigator.exploreFile.loadFileFromZip(absPath, 0, fileSize: fileinfo.size);
//            var thumbNail = content.indexContent[0];
//            exploreNavigator.putThmnailFile(fileinfo, thumbNail);
//            return thumbNail;
//          }),
//        );
        return Image(
            image: FutureImageProvider(
              exploreNavigator.getFileId(fileinfo),
              () async {
                ExtractCO content = await exploreNavigator.exploreFile.loadFileFromZip(absPath, 0, fileSize: fileinfo.size);
                var thumbNail = content.indexContent[0];
                exploreNavigator.putThmnailFile(fileinfo, thumbNail);
                return ImageCompress.thumbNailImage(thumbNail);
              },
            ),
            errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
              logger.d(exception);
              return Icon(Icons.broken_image);
            });

//        ExtractCO content = await exploreNavigator.exploreFile.loadFileFromZip(absPath, 0, fileSize: fileinfo.size);
//        var thumbNail = content.indexContent[0];
//        exploreNavigator.putThmnailFile(fileinfo, thumbNail);
//        return Image.memory(thumbNail);
      } else {
//        WholeFileContentCO content = await exploreNavigator.exploreFile.loadWholeFile(absPath);
//        var thumbNail = content.content;
//        exploreNavigator.putThmnailFile(fileinfo, thumbNail);
//        return Image.memory(content.content);
        return Image(
            image: FutureImageProvider(exploreNavigator.getFileId(fileinfo), () async {
              WholeFileContentCO content = await exploreNavigator.exploreFile.loadWholeFile(absPath);
              var thumbNail = content.content;
              exploreNavigator.putThmnailFile(fileinfo, thumbNail);

              ///这里必须要把图压缩再显示，不然内存缓存很容易就需要删除旧图片
              return ImageCompress.thumbNailImage(thumbNail);
            }),
            errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
              return Icon(Icons.broken_image);
            });

//        return FadeInImage(
//          placeholder: CacheImageProvider(exploreNavigator.getFileId(fileinfo)),
//          placeholderErrorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
//            return Icon(Icons.image);
//          },
//          image: FutureImageProvider(exploreNavigator.getFileId(fileinfo), () async {
//            WholeFileContentCO content = await exploreNavigator.exploreFile.loadWholeFile(absPath);
//            var thumbNail = content.content;
//            exploreNavigator.putThmnailFile(fileinfo, thumbNail);
//            return thumbNail;
//            return thumbNail;
//          }),
//        );
      }
    } else {
      return Icon(Icons.folder_open);
    }

//    return FutureBuilder<Widget>(future: () async {
//      if (fileinfo.isDirectory) {
//        return Icon(Icons.folder);
//      } else if ((Constants.COMPRESS_AND_IMAGE_FILE).contains((p.extension(fileinfo.filename)))) {
//        if (Utils.isCompressFile(fileinfo.filename)) {
//          return FadeInImage(
//            placeholder: CacheImageProvider(exploreNavigator.getFileId(fileinfo)),
//            placeholderErrorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
//              return Icon(Icons.image);
//            },
//            image: FutureImageProvider(exploreNavigator.getFileId(fileinfo), () async {
//              ExtractCO content = await exploreNavigator.exploreFile.loadFileFromZip(absPath, 0, fileSize: fileinfo.size);
//              var thumbNail = content.indexContent[0];
//              exploreNavigator.putThmnailFile(fileinfo, thumbNail);
//              return thumbNail;
//            }),
//          );
//
//          ExtractCO content = await exploreNavigator.exploreFile.loadFileFromZip(absPath, 0, fileSize: fileinfo.size);
//          var thumbNail = content.indexContent[0];
//          exploreNavigator.putThmnailFile(fileinfo, thumbNail);
//          return Image.memory(thumbNail);
//        } else {
//          WholeFileContentCO content = await exploreNavigator.exploreFile.loadWholeFile(absPath);
//          var thumbNail = content.content;
//          exploreNavigator.putThmnailFile(fileinfo, thumbNail);
//          return Image.memory(content.content);
//        }
//      } else {
//        return Icon(Icons.folder_open);
//      }
//    }(), builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
//      if (snapshot.connectionState == ConnectionState.done) {
//        if (snapshot.hasError) {
//          logger.e(snapshot.error);
//          return Icon(Icons.error);
//        } else {
//          return snapshot.data;
//        }
//      } else {
//        return Center(child: LoadingWidget());
//      }
//    });
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
      } else if ((Constants.COMPRESS_AND_IMAGE_FILE).contains((p.extension(fileinfo.filename)))) {
        FileContentCO content;
        if (Utils.isCompressFile(fileinfo.filename)) {
          content = await Utils.getFileFromZip(0, smbVO);
        } else {
          content = await Utils.getWholeFile(smbVO);
        }
        return Image.memory(content.content, errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
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
