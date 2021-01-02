import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/dao/SmbVO.dart';
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
}

class ImageViewerNavigator extends SmbViewerNavigator {
  List<DirectoryCO> _iterFiles;

  SmbVO getSmbByIndex(int index) {
    if (index >= 0 && index < _iterFiles.length) {
      return _smbVO.copy()..absPath = Utils.joinPath(p.dirname(_smbVO.absPath), _iterFiles[index].filename);
    } else {
      throw Exception("getSmbByIndex ${index} out of bound");
    }
  }

  String getFilename(int index) {
    return _iterFiles[index].filename;
  }

  @override
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

  @override
  int getLength() {
    return _iterFiles.length;
  }

  @override
  SmbVO _getCurSmbVO() {
    return _smbVO;
  }

  @override
  Future<void> starCurFile(int star) {
    Repository.upsertFileKey(getFilename(getCurIndex()), star: star);
    notifyListeners();
  }

  @override
  void closeViewer() {
    Repository.upsertFileKey(getFilename(getCurIndex()),
        recentReadTime: beginTime, increReadTime: (DateTime.now().millisecondsSinceEpoch - beginTime.millisecondsSinceEpoch) ~/ 1000);
  }

  @override
  Future<FileContentCO> getContent(int index, {forceFromSource: false}) async {
    var copy = _smbVO.copy();
    copy.absPath = p.join(p.dirname(copy.absPath), _iterFiles[index].filename);
    return await Utils.getWholeFile(copy, forceFromSource: forceFromSource);
  }

  @override
  String getCurFilename() {
    return getFilename(getCurIndex());
  }

  ImageViewerNavigator(bool detailToggle, int index, SmbVO smbVO, FileInfoPO fileInfoPO, this._iterFiles) : super(detailToggle, index, smbVO, fileInfoPO);
}

class ZipNavigator extends ViewerNavigator {
  final ExploreNavigator exploreNavigator;

  bool _detailToggle = false; //要不要打开viewer内的控制面板
  var _preloadPageController = PreloadPageController(initialPage: 0);
  DateTime beginTime;

//  WebDavClient client = WebDavClient("http://109.131.14.238:37536/", "", "", "");
  int _index;
  FileInfoPO _fileInfoPO;
  int fileNum;
  FileKeyPO fileKeyPO;
  String absPath;

  ZipNavigator(this.exploreNavigator, this.fileNum, this.absPath, this._index);

  @override
  Future<void> refreshView() async {
    fileKeyPO = await Repository.getFileKey(getCurFilename());
  }

  int getCurIndex() {
    return _index;
  }

  int getLength() {
    return fileNum;
  }

  void starCurFile(int star) {
    throw UnimplementedError();
  }

  void closeViewer() {
    // Repository.upsertFileKey(p.basename(_fileInfoPO.absPath),
    //     recentReadTime: beginTime,
    //     increReadTime: (DateTime.now().millisecondsSinceEpoch -
    //         beginTime.millisecondsSinceEpoch) ~/
    //         1000);
    // Repository.upsertFileInfo(
    //     _smbVO.absPath, _smbVO.id, _smbVO.nickName, _fileInfoPO);
  }

  Future<FileContentCO> getContent(int index, {forceFromSource: false}) async {
    throw UnimplementedError();
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
    notifyListeners();
  }

  String getCurFilename() {
    return "test webdav";
  }

  PreloadPageController getController() {
    return _preloadPageController;
  }

  @override
  Future<void> saveCurImage(BuildContext context) {
    // TODO: implement saveCurImage
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> getImage(int index, {forceFromSource = false}) async {
    var extractCO = await exploreNavigator.exploreFile.loadFileFromZip(absPath, index);
    return extractCO.indexContent[index];
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

class ViewBottom extends StatefulWidget {
  @override
  _ViewBottomState createState() => _ViewBottomState();
}

class _ViewBottomState extends State<ViewBottom> {
  int sliderValue = 0;

  @override
  Widget build(BuildContext context) {
    ViewerNavigator viewerNavigator = Provider.of<ViewerNavigator>(context);
    if (viewerNavigator.getDetailToggle()) {
      return Container(
          height: 100,
          child: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: Slider(
                  value: sliderValue.toDouble(),
                  min: 0,
                  max: (viewerNavigator.getLength() - 1).toDouble(),
                  onChanged: (value) {
                    if (value.round() != sliderValue) {
                      sliderValue = value.toInt();
                      viewerNavigator.jumpTo(sliderValue);
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
                ))
              ],
            )
          ]));
    } else {
      return SizedBox.shrink();
    }
  }
}

class StarButton2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ViewerNavigator viewerNavigator = Provider.of<ViewerNavigator>(context);
//    FileKeyPO fileKey = viewerNavigator.fileKeyPO;
    FileKeyPO fileKey = null;
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
  final int readPages; //看到第几页。
  final String absPath;
  final List<DirectoryCO> pwdFiles;
  final ExploreNavigator exploreNavigator;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: () async {
        if (Utils.isCompressOrImageFile(absPath)) {
          FileContentCO content;
          ExtractCO zip;
          if (Utils.isCompressFile(absPath)) {
            zip = await exploreNavigator.exploreFile.getFileNums(absPath);
//            content = await Utils.getFileFromZip(readPages, pageSmbVO, forceFromSource: true);
          }
//          else {
//
//            content = await Utils.getWholeFile(pageSmbVO, forceFromSource: true);
//          }
//          FileInfoPO filePo = FileInfoPO()..copyFromFileContentCO(content);
          return MultiProvider(providers: [
            ChangeNotifierProvider<ViewerNavigator>(
              create: (context) {
                if (Utils.isCompressFile(absPath)) {
//                  return SmbViewerNavigator(false, 0, pageSmbVO, filePo);
                  return ZipNavigator(exploreNavigator, zip.fileNum, absPath, readPages);
                } else if (Utils.isImageFile(absPath)) {
                  List<DirectoryCO> filterDirectory = pwdFiles.where((element) {
                    return element.isDirectory == false && Utils.isImageFile(element.filename);
                  }).toList();
//                  return ImageViewerNavigator(false, 0, pageSmbVO, filePo, filterDirectory);
                  return ImageViewerNavigator(false, 0, null, null, filterDirectory);
                } else {
                  throw Exception("Invalid file");
                }
              },
              lazy: false,
            ),
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

  FutureViewerChecker(this.readPages, this.absPath, this.pwdFiles, this.exploreNavigator);
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
