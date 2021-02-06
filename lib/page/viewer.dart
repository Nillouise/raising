import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:popup_menu/popup_menu.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/image/ExploreCO.dart';
import 'package:raising/image/ExtractCO.dart';
import 'package:raising/model/ExploreNavigator.dart';

import '../util.dart';

var logger = Logger();

enum FileType { img, compress }

abstract class ViewerNavigator extends ChangeNotifier {
  Future<void> refreshView();

  int getCurIndex();

  int getLength();

  void starCurFile(int star);

  void closeViewer();

  Future<Uint8List> getImage(int index, {forceFromSource: false});

  void jumpTo(int index);

  bool getDetailToggle();

  String getTitle();

  void setDetailToggle(bool toggle);

  String getCurFilename();

  PreloadPageController getController();

  Future<void> saveCurImage(BuildContext context);

  void startTimerFlip(int seconds) {}

  void cancelTimerFlip() {}

  ///TODO:这种从数据库获取数据展示，我又遇到一个问题，就是要不要用future？
  FileKeyPO getFileKeyPO();
}

class SmbViewerNavigator extends ViewerNavigator {
  bool _detailToggle = false; //要不要打开viewer内的控制面板
  var _preloadPageController = PreloadPageController(initialPage: 0);
  DateTime beginTime;
  SmbVO _smbVO;
  int _index;
  FileInfoPO _fileInfoPO;
  FileKeyPO fileKeyPO;

  void recordWhenExist() {}

  @override
  Future<void> refreshView() async {
    fileKeyPO = await Repository.getFileKey(getCurFilename());
  }

  int getCurIndex() {
    return _index;
  }

  int getLength() {
    return _fileInfoPO.fileNum;
  }

  SmbVO _getCurSmbVO() {
    return _smbVO;
  }

  void starCurFile(int star) {
    Repository.upsertFileKey(p.basename(_smbVO.absPath), star: star);
    refreshView().then((value) => notifyListeners());
  }

  void closeViewer() {
    //TODO:这里需要处理
    Repository.upsertFileKey(p.basename(_smbVO.absPath),
        recentReadTime: beginTime, increReadTime: (DateTime.now().millisecondsSinceEpoch - beginTime.millisecondsSinceEpoch) ~/ 1000);
    Repository.upsertFileInfo(_smbVO.absPath, _smbVO.id, _smbVO.nickName, _fileInfoPO);
  }

  Future<FileContentCO> getContent(int index, {forceFromSource: false}) async {
    return await Utils.getFileFromZip(index, _smbVO, forceFromSource: forceFromSource);
  }

  void jumpTo(int index) {
    _preloadPageController.jumpToPage(index);
  }

  bool getDetailToggle() {
    return _detailToggle;
  }

  String getTitle() {
    return getCurFilename();
  }

  void setDetailToggle(bool toggle) {
    _detailToggle = toggle;
    notifyListeners();
  }

  String getCurFilename() {
    return p.basename(_smbVO.absPath);
  }

  PreloadPageController getController() {
    return _preloadPageController;
  }

  Future<void> saveCurImage(BuildContext context) async {
    var content = await getContent(getCurIndex(), forceFromSource: true);
    try {
      String dir = (await getTemporaryDirectory()).path;
      await new Directory('$dir/raising').create();
      var pa = '$dir/raising/${_getCurSmbVO().absPath}${getCurIndex()}T${DateTime.now().millisecondsSinceEpoch}.${p.extension(content.absFilename)}';
      File file = new File(pa);
      file.writeAsBytes(content.content);
      var bool = await GallerySaver.saveImage(pa);
      if (bool) {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image successful")));
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image failed")));
      }
    } catch (e) {
      logger.e(e);
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image failed" + e)));
    }
  }

  SmbViewerNavigator(this._detailToggle, this._index, this._smbVO, this._fileInfoPO) {
    beginTime = DateTime.now();
  }

  @override
  Future<Uint8List> getImage(int index, {forceFromSource = false}) {
    // TODO: implement getImage
    throw UnimplementedError();
  }

  @override
  FileKeyPO getFileKeyPO() {
    // TODO: implement getFileKeyPO
    throw UnimplementedError();
  }
}

//TODO：需要做新的ImageViewerNavigator
//class ImageViewerNavigator extends SmbViewerNavigator {
//  List<DirectoryCO> _iterFiles;
//
//  SmbVO getSmbByIndex(int index) {
//    if (index >= 0 && index < _iterFiles.length) {
//      return _smbVO.copy()..absPath = Utils.joinPath(p.dirname(_smbVO.absPath), _iterFiles[index].filename);
//    } else {
//      throw Exception("getSmbByIndex ${index} out of bound");
//    }
//  }
//
//  String getFilename(int index) {
//    return _iterFiles[index].filename;
//  }
//
//  @override
//  Future<void> saveCurImage(BuildContext context) async {
//    var content = await getContent(getCurIndex(), forceFromSource: true);
//    try {
//      String dir = (await getTemporaryDirectory()).path;
//      await new Directory('$dir/raising').create();
//      var pa = '$dir/raising/${_getCurSmbVO().absPath}${getCurIndex()}T${DateTime.now().millisecondsSinceEpoch}.${p.extension(content.absFilename)}';
//      File file = new File(pa);
//      file.writeAsBytes(content.content);
//      var bool = await GallerySaver.saveImage(pa);
//      if (bool) {
//        Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image successful")));
//      } else {
//        Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image failed")));
//      }
//    } catch (e) {
//      logger.e(e);
//      Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image failed" + e)));
//    }
//  }
//
//  @override
//  int getLength() {
//    return _iterFiles.length;
//  }
//
//  @override
//  SmbVO _getCurSmbVO() {
//    return _smbVO;
//  }
//
//  @override
//  Future<void> starCurFile(int star) {
//    Repository.upsertFileKey(getFilename(getCurIndex()), star: star);
//    notifyListeners();
//  }
//
//  @override
//  void closeViewer() {
//    Repository.upsertFileKey(getFilename(getCurIndex()),
//        recentReadTime: beginTime, increReadTime: (DateTime.now().millisecondsSinceEpoch - beginTime.millisecondsSinceEpoch) ~/ 1000);
//  }
//
//  @override
//  Future<FileContentCO> getContent(int index, {forceFromSource: false}) async {
//    var copy = _smbVO.copy();
//    copy.absPath = p.join(p.dirname(copy.absPath), _iterFiles[index].filename);
//    return await Utils.getWholeFile(copy, forceFromSource: forceFromSource);
//  }
//
//  @override
//  String getCurFilename() {
//    return getFilename(getCurIndex());
//  }
//
//  ImageViewerNavigator(bool detailToggle, int index, SmbVO smbVO, FileInfoPO fileInfoPO, this._iterFiles) : super(detailToggle, index, smbVO, fileInfoPO);
//}

class ZipNavigator extends ViewerNavigator {
  final ExploreNavigator exploreNavigator;
  final ExploreCO exploreCO;

  bool _detailToggle = false; //要不要打开viewer内的控制面板
  var _preloadPageController = PreloadPageController(initialPage: 0);
  DateTime beginTime;

  Timer flipTimer;

  int _index;
  int fileNum;
  String absPath;
  FileKeyPO fileKeyPO;

  ZipNavigator(this.exploreNavigator, this.exploreCO, this.fileNum, this.absPath, this._index);

  Future<void> init() async {
    String fileId = exploreNavigator.getFileId(exploreCO);
    fileKeyPO = await exploreNavigator.getFileKeyPO(fileId);
    if (fileKeyPO == null) {
      fileKeyPO = FileKeyPO(fileId: exploreNavigator.getFileId(exploreCO), filename: exploreCO.filename, star: 0, recentReadTime: DateTime.now(), comment: "", readLength: 0);
    }
  }

  void startTimerFlip(int seconds) {
    flipTimer?.cancel();
    flipTimer = Timer.periodic(Duration(seconds: seconds), (Timer t) {
      if (getCurIndex() >= getLength() - 1) {
        flipTimer.cancel();
        return;
      }
      jumpTo(getCurIndex() + 1);
    });
  }

  void cancelTimerFlip() {
    flipTimer?.cancel();
  }

  @override
  Future<void> refreshView() async {}

  int getCurIndex() {
    return _index;
  }

  int getLength() {
    return fileNum;
  }

  void starCurFile(int star) {
    exploreNavigator.saveReadInfo(fileKeyPO..star = star);
    refreshView().then((value) => notifyListeners());
  }

  void closeViewer() {
    ///TODO:这里需要处理fileKey的情况。
    exploreNavigator.saveReadInfo(fileKeyPO
      ..fileId = exploreNavigator.getFileId(exploreCO)
      ..filename = exploreCO.filename
      ..recentReadTime = DateTime.now()
      ..readLength = _index);
  }

  void jumpTo(int index) {
    _preloadPageController.jumpToPage(index);
    _index = index;
    notifyListeners();
  }

  bool getDetailToggle() {
    return _detailToggle;
  }

  String getTitle() {
    return getCurFilename();
  }

  void setDetailToggle(bool toggle) {
    _detailToggle = toggle;
    if (toggle) {
      cancelTimerFlip();
    }
    notifyListeners();
  }

  PreloadPageController getController() {
    return _preloadPageController;
  }

  ///这里应该先尝试直接再读取原图保存，这样不行之类，再保存压缩图。
  @override
  Future<void> saveCurImage(BuildContext context) async {
    var content = await _getExtract(getCurIndex(), forceFromSource: true);
    try {
      String dir = (await getTemporaryDirectory()).path;
      await new Directory('$dir/raising').create();
      File file;
      String pa;
      for (int i = 0;; i++) {
        pa = \'$dir/raising/${p.basename(fileKeyPO.filename)}P${getCurIndex()}${i > 0 ? "(" + i.toString() + ")" : ""}${p.extension(content.indexPath[getCurIndex()])}\';
        file = File(pa);
        if (!file.existsSync()) {
          break;
        }
      }
      await file.writeAsBytes(content.indexContent[getCurIndex()]);
      var bool = await GallerySaver.saveImage(pa);
      if (bool) {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image successful")));
      } else {
        Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image failed")));
      }
    } catch (e) {
      logger.e(e);
      Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image failed" + e.toString())));
    }
  }

  Future<ExtractCO> _getExtract(int index, {forceFromSource = false}) async {
    var extractCO = await exploreNavigator.exploreFile.loadFileFromZip(absPath, index);
    return extractCO;
  }

  @override
  Future<Uint8List> getImage(int index, {forceFromSource = false}) async {
    var extractCO = await _getExtract(index, forceFromSource: forceFromSource);
    return extractCO?.indexContent[index];
  }

  @override
  FileKeyPO getFileKeyPO() {
    return fileKeyPO;
  }

  @override
  String getCurFilename() {
    return fileKeyPO?.filename;
  }
}

Area getArea(Offset offset, Size size) {
  double pecentage = offset.dx / size.width;
  if (pecentage < 0.3) return Area.lef;
  if (pecentage < 0.6)
    return Area.middle;
  else
    return Area.right;
}

class ViewerBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ViewerNavigator viewerNavigator = Provider.of<ViewerNavigator>(context, listen: false);
    return Center(
      child: GestureDetector(
        child: Container(
            child: PreloadPageView.builder(
          preloadPagesCount: 1,
          itemCount: viewerNavigator.getLength(),
          itemBuilder: (BuildContext context, int index) => FutureImage(index),
          controller: viewerNavigator.getController(),
          onPageChanged: (int position) {
            print('page changed. current: $position');
          },
          physics: new NeverScrollableScrollPhysics(),
        )),
        onPanDown: (DragDownDetails e) {
          //打印手指按下的位置(相对于屏幕)
          Offset globalPosition = e.globalPosition;
          logger.d("用户手指按下：${globalPosition}");
          RenderBox findRenderObject = context.findRenderObject();
          Size size = findRenderObject.size;
          Area area = getArea(globalPosition, size);
          if (area == Area.lef && viewerNavigator.getCurIndex() > 0) {
            viewerNavigator.jumpTo(viewerNavigator.getCurIndex() - 1);
          } else if (area == Area.right && viewerNavigator.getCurIndex() < viewerNavigator.getLength() - 1) {
            viewerNavigator.jumpTo(viewerNavigator.getCurIndex() + 1);
          } else if (area == Area.middle) {
            viewerNavigator.setDetailToggle(!viewerNavigator.getDetailToggle());
          }
        },
      ),
    );
  }
}

class ViewerAppBar extends StatefulWidget implements PreferredSizeWidget {
  ViewerAppBar({Key key})
      : preferredSize = Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize; // default is 56.0

  @override
  _ViewerAppBarState createState() => _ViewerAppBarState();
}

class _ViewerAppBarState extends State<ViewerAppBar> {
  @override
  Widget build(BuildContext context) {
    ViewerNavigator viewerNavigator = Provider.of<ViewerNavigator>(context);
    //TODO：这里还要改，不然会闪烁，看看加个动画，还是参考medium改改
    if (viewerNavigator.getDetailToggle()) {
      return AppBar(title: Text(viewerNavigator.getCurFilename()));
    } else {
      return SizedBox.shrink();
    }
  }
}

///TODO:现在这个bottom打开时，会被图片阻挡，就是说图片如何沾满下面的话，这个bottom根本没能显示出来。
class ViewBottom extends StatefulWidget {
  @override
  _ViewBottomState createState() => _ViewBottomState();
}

class _ViewBottomState extends State<ViewBottom> {
  @override
  Widget build(BuildContext context) {
    ViewerNavigator viewerNavigator = Provider.of<ViewerNavigator>(context);
    if (viewerNavigator.getDetailToggle()) {
      return Container(
          height: 100,
          color: Colors.white,
          child: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: Slider(
                  value: viewerNavigator.getCurIndex().toDouble(),
                  min: 0,
                  max: (viewerNavigator.getLength() - 1).toDouble(),
                  onChanged: (value) {
                    if (value.round() != viewerNavigator.getCurIndex()) {
                      viewerNavigator.jumpTo(value.round());
                    }
                  },
                )),
                Text("${viewerNavigator.getCurIndex() + 1} / ${viewerNavigator.getLength()}")
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(child: StarButton2()),
                Expanded(
                    child: FlatButton(
                  onPressed: () async {
                    try {
                      viewerNavigator.saveCurImage(context);
                    } catch (e) {
                      logger.e(e);
                      Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image failed" + e)));
                    }
                  },
                  child: Text(
                    "截图",
                    style: TextStyle(fontSize: 18.0),
                  ),
                )),
                Expanded(
                  child: FlipTimer(),
                )
//                FlipTimer()
              ],
            )
          ]));
    } else {
      return SizedBox.shrink();
    }
  }
}

class FlipTimer extends StatelessWidget {
  final GlobalKey btnKey = GlobalKey();
  ViewerNavigator viewerNavigator;

//  void showPopup(Offset offset) {
//    PopupMenu menu = PopupMenu(
//      // backgroundColor: Colors.teal,
//      // lineColor: Colors.tealAccent,
//      maxColumn: lst.length,
//      items: lst,
//    );
//    menu.show(rect: Rect.fromPoints(offset, offset));
//  }

  void onClickMenu(MenuItemProvider item) {
    print('Click menu -> ${item.menuTitle}');
    viewerNavigator.startTimerFlip(int.parse(item.menuTitle));
    viewerNavigator.setDetailToggle(false);
  }

  void timerMenu() {
    List<MenuItem> lst = List<MenuItem>();
    for (int i = 1; i <= 12; i++) {
      lst.add(MenuItem(title: (i * 2).toString()));
    }
    PopupMenu menu = PopupMenu(
        // backgroundColor: Colors.teal,
        // lineColor: Colors.tealAccent,
        // maxColumn: 2,
        maxColumn: 3,
        items: lst,
        onClickMenu: onClickMenu);
    menu.show(widgetKey: btnKey);
  }

  @override
  Widget build(BuildContext context) {
    PopupMenu.context = context;
    viewerNavigator = Provider.of<ViewerNavigator>(context);
    return Container(
      child: MaterialButton(
        key: btnKey,
//        height: 45.0,
        onPressed: timerMenu,
        child: Text('定时器'),
      ),
    );
  }
}

class StarButton2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ViewerNavigator viewerNavigator = Provider.of<ViewerNavigator>(context);
    FileKeyPO fileKey = viewerNavigator.getFileKeyPO();
    if (fileKey?.star != null && fileKey.star > 0) {
      return FlatButton(
        onPressed: () async {
          viewerNavigator.starCurFile(0);
        },
        child: Icon(
          Icons.star,
          color: Colors.yellow[800],
        ),
      );
    } else {
      return FlatButton(
        onPressed: () async {
          viewerNavigator.starCurFile(5);
        },
        child: Icon(Icons.star_border),
      );
    }
  }
}

class StarButton extends StatefulWidget {
  StarButton();

  @override
  _StarButtonState createState() => _StarButtonState();
}

class _StarButtonState extends State<StarButton> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(future: () async {
      ViewerNavigator viewerNavigator = Provider.of<ViewerNavigator>(context);
      FileKeyPO fileKey = await Repository.getFileKey(viewerNavigator.getCurFilename());
      if (fileKey?.star != null && fileKey.star > 0) {
        return FlatButton(
          onPressed: () async {
            viewerNavigator.starCurFile(0);
          },
          child: Icon(
            Icons.star,
            color: Colors.yellow[800],
          ),
        );
      } else {
        return FlatButton(
          onPressed: () async {
            viewerNavigator.starCurFile(5);
          },
          child: Icon(Icons.star_border),
        );
      }
    }(), builder: (BuildContext context, AsyncSnapshot snapshot) {
      if (snapshot.hasData) {
        if (snapshot.data != null) {
          return snapshot.data;
        } else {
          return Icon(Icons.star_border);
        }
      } else {
        return Icon(Icons.error);
      }
    });
  }

  @override
  void initState() {
    super.initState();
  }
}

class Viewer extends StatefulWidget {
  Viewer();

  @override
  State<StatefulWidget> createState() => ViewerState();
}

class ViewerState extends State<Viewer> {
  ViewerNavigator _navigator;

  ViewerState();

  @override
  Widget build(BuildContext context) {
    _navigator = Provider.of<ViewerNavigator>(context, listen: false);
    return Scaffold(
      appBar: ViewerAppBar(),
      body: ViewerBody(),
      extendBodyBehindAppBar: true,
      extendBody: true,
      bottomNavigationBar: ViewBottom(),
    );
  }

  @override
  void dispose() {
    logger.d("Viewer dispose");
    _navigator.closeViewer();
    super.dispose();
  }
}

enum Area { lef, right, middle }

/**
 * 这里应当不再预先检查文件信息，检查机制应该再View的图中，反正途中也有可能出现问题。
 * 这里应当检查缓存，对ExploreFile进行验脏，如果缓存在1个小时内，则直接先用缓存里的数据。
 */
class FutureViewerChecker extends StatelessWidget {
  final ExploreCO exploreco;
  final int readPages; //看到第几页。
  final String absPath;

//  final List<DirectoryCO> pwdFiles;
  final ExploreNavigator exploreNavigator;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: () async {
        if (Utils.isCompressOrImageFile(absPath)) {
          ExtractCO zip;
          ViewerNavigator viewerNavigator;
          if (Utils.isCompressFile(absPath)) {
            zip = await exploreNavigator.exploreFile.getFileNums(absPath);
            ZipNavigator zipNavigator = ZipNavigator(exploreNavigator, exploreco, zip.fileNum, absPath, readPages);
            await zipNavigator.init();
            viewerNavigator = zipNavigator;
//            content = await Utils.getFileFromZip(readPages, pageSmbVO, forceFromSource: true);
          }

          return MultiProvider(providers: [
            ChangeNotifierProvider<ViewerNavigator>(
              create: (context) {
                if (Utils.isCompressFile(absPath)) {
//                  return SmbViewerNavigator(false, 0, pageSmbVO, filePo);
//                  return ZipNavigator(exploreNavigator, exploreco, zip.fileNum, absPath, readPages);
                  return viewerNavigator;
                } else if (Utils.isImageFile(absPath)) {
                  //TODO:需要做新的ImageViewerNavigator
                  return null;
//                  List<DirectoryCO> filterDirectory = pwdFiles.where((element) {
//                    return element.isDirectory == false && Utils.isImageFile(element.filename);
//                  }).toList();
////                  return ImageViewerNavigator(false, 0, pageSmbVO, filePo, filterDirectory);
//                  return ImageViewerNavigator(false, 0, null, null, filterDirectory);
                } else {
                  throw Exception("Invalid file");
                }
              },
              lazy: false,
            )
          ], child: Viewer());
        } else {
          return Text("Invalid file");
        }
      }(),
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            //TODO:这里应显示错误页
            return Text("Error: ${snapshot.error}");
          } else {
            return snapshot.data;
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  FutureViewerChecker(this.exploreco, this.readPages, this.absPath, this.exploreNavigator);
}

class FutureImage extends StatelessWidget {
  final int index;

  @override
  Widget build(BuildContext context) {
    ViewerNavigator viewerNavigator = Provider.of<ViewerNavigator>(context, listen: false);

    return FutureBuilder<Uint8List>(
      future: () async {
        return viewerNavigator.getImage(index);
      }(),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Text("Error: ${snapshot.error}");
          } else {
            return Image.memory(snapshot.data);
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  FutureImage(this.index);
}
