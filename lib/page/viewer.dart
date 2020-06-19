import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/model/file_info.dart';
import 'package:raising/model/smb_navigation.dart';

var logger = Logger();

class ViewerNavigator extends ChangeNotifier {}

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
  int _index = 0;

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
            create: (context) => ViewerNavigator(),
            lazy: false,
          ),
        ],
        child: GestureDetector(
          child: Container(
            child: showPage(context, _index),
          ),
          onPanDown: (DragDownDetails e) {
            //打印手指按下的位置(相对于屏幕)
            Offset globalPosition = e.globalPosition;
            logger.d("用户手指按下：${globalPosition}");
            RenderBox findRenderObject = context.findRenderObject();
            Size size = findRenderObject.size;
            Area area = getArea(globalPosition, size);
            if (area == Area.lef) {
              setState(() {
                _index--;
              });
            } else if (area == Area.right) {
              setState(() {
                _index++;
              });
            } else {
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text("middle")));
            }
          },
        ));

//    return showPage(context,0);
  }

  Widget showPage(BuildContext context, int index) {
    return FutureBuilder<SmbHalfResult>(
      future: () async {
        SmbNavigation catalog = Provider.of<SmbNavigation>(context);
        FileRepository fileRepository =
            Provider.of<FileRepository>(context, listen: false);
        var absPath = path.join(catalog.path, widget.filename);

        FileInfo fileInfo =
            await fileRepository.findByabsPath(absPath, catalog.smbId);
        bool needFileDetailInfo = (fileInfo == null ||
            fileInfo.length == null ||
            fileInfo.length == 0);

        return Smb.getCurrentSmb().loadImageFromIndex(widget.filename, index,
            needFileDetailInfo: needFileDetailInfo);
      }(),
      builder: (BuildContext context, AsyncSnapshot<SmbHalfResult> snapshot) {
        // 请求已结束
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return Text("Error: ${snapshot.error}");
          } else {
            // 请求成功，显示数据
            return Image.memory(snapshot.data.result[index].content);
          }
        } else {
          // 请求未结束，显示loading
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
