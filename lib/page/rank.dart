import 'package:flutter/material.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/Repository.dart';

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
      },
      separatorBuilder: (context, index) => Divider(height: .0),
    );
  }

  void _retrieveData() {
    int size = 100;
    Repository.historyFileInfo("recentReadTime desc", offset, size + 1).then((e) => {
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
          BottomNavigationBarItem(icon: Icon(Icons.filter_1), title: Text('月榜')),
          BottomNavigationBarItem(icon: Icon(Icons.filter_2), title: Text('季榜')),
          BottomNavigationBarItem(icon: Icon(Icons.filter_3), title: Text('年榜')),
          BottomNavigationBarItem(icon: Icon(Icons.filter), title: Text('总榜')),
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
