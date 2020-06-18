import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:raising/channel/Smb.dart';

var logger = Logger();

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
    return GestureDetector(
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
          Scaffold.of(context).showSnackBar(SnackBar(content: Text("middle")));
        }
      },
    );

//    return showPage(context,0);
  }

  Widget showPage(BuildContext context, int index) {
    return FutureBuilder<Uint8List>(
      future: () {
        return Smb.getCurrentSmb().loadImageFromIndex(widget.filename, index);
      }(),
      builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
        // 请求已结束
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return Text("Error: ${snapshot.error}");
          } else {
            // 请求成功，显示数据s
            return Image.memory(snapshot.data);
          }
        } else {
          // 请求未结束，显示loading
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
