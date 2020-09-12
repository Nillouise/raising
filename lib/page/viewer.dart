import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:provider/provider.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/model/file_info.dart';
import 'package:raising/model/smb_navigation.dart';

import '../util.dart';

var logger = Logger();

class ViewerNavigator extends ChangeNotifier {
  bool _detailToggle = false;
  int _index = 0;
  int _pagelength = 0;
  String _absFilename;
  DateTime beginTime;

  var _preloadPageController = PreloadPageController(initialPage: 0);

  get preloadPageController => _preloadPageController;

  set preloadPageController(preloadPageController) {
    _preloadPageController = preloadPageController;
  }

  int get index => _index;

  set index(int index) {
    _index = index;
    notifyListeners();
  }

  int get pagelength => _pagelength;

  set pagelength(int pagelength) {
    _pagelength = pagelength;
    notifyListeners();
  }

  String get absFilename => _absFilename;

  set absFilename(String absFilename) {
    _absFilename = absFilename;
    notifyListeners();
  }

  bool get detailToggle => _detailToggle;

  set detailToggle(value) {
    _detailToggle = value;
    notifyListeners();
  }

  ViewerNavigator(this._detailToggle, this._index, this._pagelength, this._absFilename);
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
          preloadPagesCount: 5,
          itemCount: viewerNavigator.pagelength,
          itemBuilder: (BuildContext context, int index) => FutureImage(index, viewerNavigator.absFilename),
          controller: viewerNavigator.preloadPageController,
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
          if (area == Area.lef && viewerNavigator.index > 0) {
            viewerNavigator.index--;
            viewerNavigator.preloadPageController.jumpToPage(viewerNavigator.index);
          } else if (area == Area.right && viewerNavigator.index < viewerNavigator.pagelength - 1) {
            viewerNavigator.index++;
            viewerNavigator.preloadPageController.jumpToPage(viewerNavigator.index);
          } else if (area == Area.middle) {
            viewerNavigator.detailToggle = !viewerNavigator.detailToggle;
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
    if (viewerNavigator.detailToggle) {
      return AppBar(title: Text("Sample App Bar"));
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
    if (viewerNavigator.detailToggle) {
      return Container(
          height: 100,
          child: Column(children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                    child: Slider(
                  value: sliderValue.toDouble(),
                  min: 0,
                  max: (viewerNavigator.pagelength - 1).toDouble(),
                  onChanged: (value) {
                    if (value.round() != sliderValue) {
                      sliderValue = value.toInt();
                      viewerNavigator.index = sliderValue;
                      viewerNavigator.preloadPageController.jumpToPage(viewerNavigator.index);
                    }
                  },
                )),
                Text("${viewerNavigator.index + 1} / ${viewerNavigator.pagelength}")
              ],
            ),
            Row(
              children: <Widget>[
                Expanded(child: StarButton(viewerNavigator.absFilename)),
                Expanded(
                    child: FlatButton(
                  onPressed: () async {
                    try {
                      SmbNavigation catalog = Provider.of<SmbNavigation>(context, listen: false);
                      ViewerNavigator viewP = Provider.of<ViewerNavigator>(context, listen: false);

                      SmbHalfResult smbHalfResult = await Utils.getImage(viewP.index, viewP.absFilename, true, catalog.share);

                      String dir = (await getTemporaryDirectory()).path;
                      await new Directory('$dir/raising').create();
                      var pa =
                          '$dir/raising/${viewP.absFilename}${viewP.index}T${DateTime.now().millisecondsSinceEpoch}.${p.extension(smbHalfResult.result[viewP.index].zipFilename)}';
                      File file = new File(pa);
                      file.writeAsBytes(smbHalfResult.result[viewP.index].content);
                      var bool = await GallerySaver.saveImage(pa);
                      if (bool) {
                        Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image successful")));
                      } else {
                        Scaffold.of(context).showSnackBar(SnackBar(content: Text("save image failed")));
                      }
                    } catch (e) {
                      logger.e(e);
                      throw e;
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

class StarButton extends StatefulWidget {
  final String absFilename;

  StarButton(this.absFilename);

  @override
  _StarButtonState createState() => _StarButtonState();
}

class _StarButtonState extends State<StarButton> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(future: () async {
      FileRepository fileRepository = Provider.of<FileRepository>(context);
      FileKey fileKey = await fileRepository.getFileKey(p.basename(widget.absFilename));

      if (fileKey?.star != null && fileKey.star > 0) {
        return FlatButton(
          onPressed: () async {
            fileRepository.upsertFileKey(p.basename(widget.absFilename), star: 0);
          },
          child: Icon(
            Icons.star,
            color: Colors.yellow[800],
          ),
        );
      } else {
        return FlatButton(
          onPressed: () async {
            fileRepository.upsertFileKey(p.basename(widget.absFilename), star: 5);
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
}

class Viewer extends StatefulWidget {
//  Viewer(this.absFilename, this.pagelength, {this.index: 0, Key key}) : super(key: key);

  final int index;
  final int pagelength;
  final String absFilename;

  Viewer(this.absFilename, this.pagelength, {this.index: 0, Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ViewerState(index, pagelength, absFilename);
}

class ViewerState extends State<Viewer> {
  int index;
  int pagelength;
  String absFilename;
  ViewerNavigator _navigator;
  FileRepository _fileRepository;

  ViewerState(this.index, this.pagelength, this.absFilename);

  @override
  Widget build(BuildContext context) {
    _fileRepository = Provider.of<FileRepository>(context, listen: false);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ViewerNavigator>(
          create: (context) => _navigator = ViewerNavigator(false, index, pagelength, absFilename)..beginTime = DateTime.now(),
          lazy: false,
        ),
      ],
      child: Scaffold(
        appBar: ViewerAppBar(),
        body: ViewerBody(),
        extendBodyBehindAppBar: true,
        extendBody: true,
        bottomNavigationBar: ViewBottom(),
      ),
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    logger.d("Viewer dispose");
    _fileRepository.upsertFileKey(p.basename(absFilename),
        clickTime: _navigator.beginTime, increReadTime: (DateTime.now().millisecondsSinceEpoch - _navigator.beginTime.millisecondsSinceEpoch) ~/ 1000);
//    _fileRepository.upsertFileInfo(absFilename, );

    super.dispose();
  }
}

enum Area { lef, right, middle }

class FutureViewerChecker extends StatelessWidget {
  final int index;
  final String absFilename;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: () async {
        SmbNavigation catalog = Provider.of<SmbNavigation>(context);
        FileRepository fileRepository = Provider.of<FileRepository>(context, listen: false);

        if (Utils.isImageFile(absFilename)) {
          SmbHalfResult halfResult = await Utils.getPreviewFile(0, absFilename, catalog.share);
          return Image.memory(halfResult.result[0].content, errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
            return Icon(Icons.error);
          });
        } else if (Utils.isCompressFile(absFilename)) {
          var smbHalfResult = await Utils.getImage(index, absFilename, true, catalog.share);
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

//        FileInfo fileInfo = await fileRepository.findByabsPath(absFilename, catalog.smbId);
        var res = await Utils.getImage(index, absFilename, false, catalog.share);
        Repository.upsertFileInfo(absFilename, catalog.smbId, catalog.smbNickName);
        return res;
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
