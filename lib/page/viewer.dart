import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/image/cache.dart';
import 'package:raising/model/file_info.dart';
import 'package:raising/model/smb_navigation.dart';
import 'package:preload_page_view/preload_page_view.dart';

var logger = Logger();

class ViewerNavigator extends ChangeNotifier {
  int _index = 0;
  Widget image;
  String filename;

  ViewerNavigator(this._index, this.filename);

  void nextpage(BuildContext context) async {
    SmbNavigation catalog = Provider.of<SmbNavigation>(context, listen: false);

    var absPath = path.join(catalog.path, filename);
    _index++;
    var result = await getImage(_index, absPath, true);
    if (result.msg == "successful") {
      image = Image.memory(result.result[_index].content);
    }
    notifyListeners();
  }

  Future<SmbHalfResult> getImage(
      int index, String absPath, bool needFileDetailInfo) async {
    var result = await getImageFromCache(absPath, index);
    if (result != null) {
      return SmbHalfResult(
          "successful", {index: ZipFileContent.content(result)});
    } else {
      SmbHalfResult smbHalfResult = await Smb.getCurrentSmb()
          .loadImageFromIndex(absPath, index,
              needFileDetailInfo: needFileDetailInfo);
      if (smbHalfResult.msg == "successful") {
        putImageToCache(absPath, index, smbHalfResult.result[index].content);
      }

      return smbHalfResult;
    }
  }
}

class Viewer extends StatefulWidget {
  Viewer(this.filename, {Key key}) : super(key: key);

  final String filename;

  @override
  _ViewerState createState() {
    return _ViewerState();
  }
}

enum Area { lef, right, middle }

class _ViewerState extends State<Viewer> {
  int index = 0;
  final controller = new PageController(initialPage: 999);
  final preloadPageController = PreloadPageController(initialPage: 0);

  Area getArea(Offset offset, Size size) {
    double pecentage = offset.dx / size.width;
    if (pecentage < 0.3) return Area.lef;
    if (pecentage < 0.6)
      return Area.middle;
    else
      return Area.right;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<ViewerNavigator>(
            create: (context) => ViewerNavigator(0, widget.filename),
            lazy: false,
          ),
        ],
        child: GestureDetector(
//          child: Container(
//            child: FutureImage(_index, widget.filename, this),
//          ),
          child: Container(
              child: PreloadPageView.builder(
            preloadPagesCount: 5,
            itemBuilder: (BuildContext context, int index) =>
                FutureImage(index, widget.filename, this),
            controller: preloadPageController,
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
            if (area == Area.lef) {
              index--;
              preloadPageController.jumpToPage(index);
            } else if (area == Area.right) {
              index++;
              preloadPageController.jumpToPage(index);
            } else {
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text("middle")));
            }
          },
        ));

//    return showPage(context,0);
  }
}

class TapWidget extends StatelessWidget {
  Area getArea(Offset offset, Size size) {
    double pecentage = offset.dx / size.width;
    if (pecentage < 0.3) return Area.lef;
    if (pecentage < 0.6)
      return Area.middle;
    else
      return Area.right;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
//          child: Container(
//            child: FutureImage(_index, widget.filename, this),
//          ),
      child: Container(
        child: Consumer<ViewerNavigator>(
          builder: (context, model, childWidget) {
            if (model.image != null) {
              return model.image;
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
      onPanDown: (DragDownDetails e) {
        //打印手指按下的位置(相对于屏幕)
        Offset globalPosition = e.globalPosition;
        logger.d("用户手指按下：${globalPosition}");
        RenderBox findRenderObject = context.findRenderObject();
        Size size = findRenderObject.size;
        Area area = getArea(globalPosition, size);

        var viewNavigator =
            Provider.of<ViewerNavigator>(context, listen: false);
        if (area == Area.lef) {
          viewNavigator.nextpage(context);
        } else if (area == Area.right) {
          viewNavigator.nextpage(context);
        } else {
          Scaffold.of(context).showSnackBar(SnackBar(content: Text("middle")));
        }
      },
    );
  }
}

class CurrentImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ViewerNavigator>(
      builder: (context, model, childWidget) {
        if (model.image != null) {
          return model.image;
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}

class FutureImage extends StatelessWidget {
  final int index;
  final String filename;
  final _ViewerState __viewerState;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SmbHalfResult>(
      future: () async {
        SmbNavigation catalog = Provider.of<SmbNavigation>(context);
        FileRepository fileRepository =
            Provider.of<FileRepository>(context, listen: false);
        var absPath = path.join(catalog.path, filename);

        FileInfo fileInfo =
            await fileRepository.findByabsPath(absPath, catalog.smbId);
        bool needFileDetailInfo = (fileInfo == null ||
            fileInfo.length == null ||
            fileInfo.length == 0);

        if (false) {
          SmbHalfResult smbHalfResult = await Smb.getCurrentSmb()
              .loadImageFromIndex(absPath, index,
                  needFileDetailInfo: needFileDetailInfo);
          if (smbHalfResult.msg == "successful") {
            await putImageToCache(
                absPath, index, smbHalfResult.result[index].content);
          }
          return smbHalfResult;
        } else {
          var smbHalfResult =
              await getImage(index, absPath, needFileDetailInfo);
          getImage(index + 1, absPath, needFileDetailInfo);
          return smbHalfResult;
        }
      }(),
      builder: (BuildContext context, AsyncSnapshot<SmbHalfResult> snapshot) {
        // 请求已结束
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return Text("Error: ${snapshot.error}");
          } else {
            return Image.memory(snapshot.data.result[index].content);
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<SmbHalfResult> getImage(
      int index, String absPath, bool needFileDetailInfo) async {
    var result = await getImageFromCache(absPath, index);
    if (result != null) {
      return SmbHalfResult(
          "successful", {index: ZipFileContent.content(result)});
    } else {
      SmbHalfResult smbHalfResult = await Smb.getCurrentSmb()
          .loadImageFromIndex(absPath, index,
              needFileDetailInfo: needFileDetailInfo);
      if (smbHalfResult.msg == "successful") {
        putImageToCache(absPath, index, smbHalfResult.result[index].content);
      }

      return smbHalfResult;
    }
  }

  FutureImage(this.index, this.filename, this.__viewerState);
}
