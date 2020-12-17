import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/util.dart';

var logger = Logger();

class HistoryPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HistoryPageState();
  }

  HistoryPage();
}

class _HistoryPageState extends State<HistoryPage> {
  int offset = 0;
  bool isGetAllData = false;
  var _data = <FileInfoPO>[_endSignal];
  static FileInfoPO _endSignal = FileInfoPO();

  //TODO:这里还需要修bug，处理缓存被删的情况
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        //如果到了表尾
        if (identical(_data[index], _endSignal)) {
          if (isGetAllData) {
            if (offset > 10) {
              return Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "没有更多了",
                    style: TextStyle(color: Colors.grey),
                  ));
            } else {
              return SizedBox.shrink();
            }
          } else {
            _retrieveData();
            return Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: SizedBox(width: 24.0, height: 24.0, child: CircularProgressIndicator(strokeWidth: 2.0)),
            );
          }
        }

//        return ListTile(title: Text(_data[index].filename));
        return ListTile(
            leading: AspectRatio(
                aspectRatio: 1,
                child: FutureBuilder<Widget>(
                  future: () async {
                    Uint8List bytes = await Utils.getThumbnailFile(_data[index].smbId, _data[index].absPath);
                    if (bytes == null) {
                      return Icon(Icons.check_box_outline_blank);
                    }
                    return Image.memory(bytes);
                  }(),
                  builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return Text("Error: ${snapshot.error}");
                      } else {
                        return snapshot.data;
                      }
                    } else {
                      return Center(child: CircularProgressIndicator());
                    }
                  },
                )),
            title: Text(_data[index].filename));
      },
      separatorBuilder: (context, index) => Divider(height: .0),
    );
  }

  void _retrieveData() {
    int size = 100;
    Repository.historyFileInfo(offset, size + 1)
        .then((e) => {
              setState(() {
                if (e.length < size + 1) {
                  _data.insertAll(_data.length - 1, e);
                  isGetAllData = true;
                  offset += e.length;
                } else {
                  _data.insertAll(_data.length - 1, e.sublist(0, size));
                  offset += size;
                }
              })
            })
        .catchError((e) {
      logger.e(e);
    });
  }
}

class ScorePage extends StatefulWidget {
  final Future<List<FileKeyPO>> Function(int, int) getFileKey;

  @override
  State<StatefulWidget> createState() {
    return _ScorePageState();
  }

  ScorePage(this.getFileKey);
}

class _ScorePageState extends State<ScorePage> {
  int offset = 0;
  bool isGetAllData = false;
  var _data = <FileKeyPO>[_endSignal];
  static FileKeyPO _endSignal = FileKeyPO();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        //如果到了表尾
        if (identical(_data[index], _endSignal)) {
          if (isGetAllData) {
            if (offset > 10) {
              return Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "没有更多了",
                    style: TextStyle(color: Colors.grey),
                  ));
            } else {
              return SizedBox.shrink();
            }
          } else {
            _retrieveData();
            return Container(
              padding: const EdgeInsets.all(16.0),
              alignment: Alignment.center,
              child: SizedBox(width: 24.0, height: 24.0, child: CircularProgressIndicator(strokeWidth: 2.0)),
            );
          }
        }
        return ListTile(title: Text(_data[index].filename));
//        return ListTile(
//          leading: AspectRatio(aspectRatio: 1, child: PreviewFile(files[index], catalog.smbVO)),
//          title: Text(files[index].filename),
//          onTap: () {
//            if (files[index].isDirectory) {
//              catalog.refreshPath(Utils.joinPath(catalog.smbVO.absPath, files[index].filename));
//            } else if (Constants.COMPRESS_AND_IMAGE_FILE.contains(p.extension(files[index].filename))) {
//              Navigator.push(
//                context,
//                MaterialPageRoute(builder: (context) => FutureViewerChecker(0, Utils.joinPath(catalog.smbVO.absPath, files[index].filename), files)),
//              );
//            }
//          },
//        );
      },
      separatorBuilder: (context, index) => Divider(height: .0),
    );
  }

  void _retrieveData() {
    int size = 100;
    widget.getFileKey(offset, size + 1).then((e) => {
          setState(() {
            if (e.length < size + 1) {
              _data.insertAll(_data.length - 1, e);
              isGetAllData = true;
              offset += e.length;
            } else {
              _data.insertAll(_data.length - 1, e.sublist(0, size));
              offset += size;
            }
          })
        });
  }
}

class RankPage extends StatefulWidget {
  RankPage({Key key}) : super(key: key);

  @override
  _RankPageState createState() {
    return _RankPageState();
  }
}

class _RankPageState extends State<RankPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onChangeBookmark() {
    setState(() {
      _onlyBookmark = !_onlyBookmark;
      ScaffoldState _state = context.findAncestorStateOfType<ScaffoldState>();
      //调用ScaffoldState的showSnackBar来弹出SnackBar
      _state.showSnackBar(
        SnackBar(
          content: Text("只显示收藏"),
          duration: Duration(seconds: 1),
        ),
      );
    });
  }

  bool _onlyBookmark = true;

  @override
  Widget build(BuildContext context) {
    IconData curBoomark = _onlyBookmark ? Icons.star_border : Icons.star;

    return Scaffold(
      body: <Widget>[
        ScorePage((page, size) async {
          return await Repository.rankFileKey14("score14 desc", page, size);
        }),
        ScorePage((page, size) async {
          return await Repository.rankFileKey14("score60 desc", page, size);
        }),
        HistoryPage(),
        Text("ok4")
      ][_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // 底部导航
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.filter_1), label: '月榜'),
          BottomNavigationBarItem(icon: Icon(Icons.filter_2), label: '季榜'),
          BottomNavigationBarItem(icon: Icon(Icons.filter_3), label: '历史'),
          BottomNavigationBarItem(icon: Icon(Icons.filter), label: '总榜'),
        ],
        currentIndex: _selectedIndex,
        fixedColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
          //悬浮按钮
          child: Icon(curBoomark),
          onPressed: _onChangeBookmark),
    );
  }
}
