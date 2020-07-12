import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:raising/model/file_info.dart';
import 'package:raising/model/smb_navigation.dart';

import '../util.dart';

var logger = Logger();

class ViewerNavigator extends ChangeNotifier {
  ViewerNavigator();
}

class Viewer extends StatefulWidget {
  Viewer(this.absFilename, this.pagelength, {this.index: 0, Key key})
      : super(key: key);

  int index = 0;
  int pagelength = 0;
  String absFilename;

  @override
  _ViewerState createState() {
    return _ViewerState();
  }
}

enum Area { lef, right, middle }

class _ViewerState extends State<Viewer> {
  var preloadPageController = PreloadPageController(initialPage: 0);

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
    preloadPageController = PreloadPageController(initialPage: 0);
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<ViewerNavigator>(
            create: (context) => ViewerNavigator(),
            lazy: false,
          ),
        ],
        child: GestureDetector(
          child: Container(
              child: PreloadPageView.builder(
            preloadPagesCount: 5,
            itemCount: widget.pagelength,
            itemBuilder: (BuildContext context, int index) =>
                FutureImage(index, widget.absFilename),
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
            if (area == Area.lef && widget.index > 0) {
              widget.index--;
              preloadPageController.jumpToPage(widget.index);
            } else if (area == Area.right &&
                widget.index < widget.pagelength - 1) {
              widget.index++;
              preloadPageController.jumpToPage(widget.index);
            } else if (area == Area.middle) {
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text("middle")));
            }
          },
        ));
  }
}

class FutureViewerChecker extends StatelessWidget {
  final int index;
  final String absFilename;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: () async {
        SmbNavigation catalog = Provider.of<SmbNavigation>(context);
        FileRepository fileRepository =
            Provider.of<FileRepository>(context, listen: false);

        FileInfo fileInfo =
            await fileRepository.findByabsPath(absFilename, catalog.smbId);

        if (Utils.isImageFile(absFilename)) {
          SmbHalfResult halfResult = await Utils.getPreviewFile(0, absFilename);
          return Image.memory(halfResult.result[0].content, errorBuilder:
              (BuildContext context, Object exception, StackTrace stackTrace) {
            return Icon(Icons.error);
          });
        } else if (Utils.isCompressFile(absFilename)) {
          var smbHalfResult = await Utils.getImage(index, absFilename, true);
          return Viewer(
            absFilename,
            smbHalfResult.result.values.first.length,
            index: index,
          );
        } else {
          return Text("invalid file");
        }
      }(),
      builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
        // 请求已结束
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
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

  FutureViewerChecker(this.index, this.absFilename);
}

class FutureImage extends StatelessWidget {
  final int index;
  final String absFilename;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SmbHalfResult>(
      future: () async {
        SmbNavigation catalog = Provider.of<SmbNavigation>(context);
        FileRepository fileRepository =
            Provider.of<FileRepository>(context, listen: false);

        FileInfo fileInfo =
            await fileRepository.findByabsPath(absFilename, catalog.smbId);
        return await Utils.getImage(index, absFilename, true,catalog.share);
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

  FutureImage(this.index, this.absFilename);
}
