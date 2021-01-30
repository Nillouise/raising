import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/image/cache.dart';

//此类还没完成

///这里的view层跟逻辑层耦合在一起了，需要找个办法处理一下。
var logger = Logger();

class CacheImageProvider extends ImageProvider<CacheImageProvider> {
  final String fileId;

  CacheImageProvider(this.fileId);

  @override
  ImageStreamCompleter load(CacheImageProvider key, DecoderCallback decode) {
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
    final Uint8List bytes = await (await CacheThumbnail.getThumbnail(fileId)).readAsBytes();

    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance?.imageCache?.evict(this);
      throw StateError('$fileId is empty and cannot be loaded as an image.');
    }

    return await decode(bytes);
  }

  @override
  Future<CacheImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CacheImageProvider>(this);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    bool res = other is CacheImageProvider && other.fileId == fileId;
    return res;
  }

  @override
  int get hashCode => fileId.hashCode;

  @override
  String toString() => '${objectRuntimeType(this, 'CacheImageProvider')}("$fileId")';
}

class HistoryPage extends StatefulWidget {
  final bool onlyBookMark;
  final Future<List<FileKeyPO>> Function(int, int, bool) getFileKeyList;

  @override
  State<StatefulWidget> createState() {
    return _HistoryPageState();
  }

  HistoryPage(this.onlyBookMark, this.getFileKeyList, {Key key}) : super(key: key);
}

class _HistoryPageState extends State<HistoryPage> {
  int offset = 0;
  bool isGetAllData = false;
  var _data = <FileKeyPO>[_endSignal];
  static FileKeyPO _endSignal = FileKeyPO();

  @override
  void initState() {
    super.initState();
  }

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
        return ListTile(
            leading: AspectRatio(
                aspectRatio: 1,
                child: Image(
                  image: CacheImageProvider(_data[index].fileId),
                  errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
                    return Icon(Icons.broken_image);
                  },
                )),
            title: Text(_data[index].filename));
      },
      separatorBuilder: (context, index) => Divider(height: .0),
    );
  }

  void _retrieveData() {
    int size = 100;
    widget
        .getFileKeyList(offset, size + 1, widget.onlyBookMark)
        .then((e) => {
              setState(() {
                var begin = _data.length - 1;
                if (e.length < size + 1) {
                  _data.insertAll(begin, e);
                  isGetAllData = true;
                  offset += e.length;
                } else {
                  _data.insertAll(begin, e.sublist(0, size));
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
  List<FileKeyPO> _data = <FileKeyPO>[_endSignal];
  static FileKeyPO _endSignal = FileKeyPO();

  @override
  void initState() {
    super.initState();
  }

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
        return ListTile(
            leading: AspectRatio(
                aspectRatio: 1,
                child: Image(
                  image: CacheImageProvider(_data[index].fileId),
                  errorBuilder: (BuildContext context, Object exception, StackTrace stackTrace) {
                    return Icon(Icons.broken_image);
                  },
                )),
            title: Text(_data[index].filename));
      },
      separatorBuilder: (context, index) => Divider(height: .0),
    );
  }

  void _retrieveData() {
    int size = 100;
    widget.getFileKey(offset, size + 1).then((e) => {
          setState(() {
            var begin = _data.length - 1;
            if (e.length < size + 1) {
              _data.insertAll(begin, e);
              isGetAllData = true;
              offset += e.length;
            } else {
              _data.insertAll(begin, e.sublist(0, size));
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
  bool _onlyBookmark = false;

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

  @override
  Widget build(BuildContext context) {
    IconData curBookmark = _onlyBookmark ? Icons.star : Icons.star_border;

    return Scaffold(
      body: <Widget>[
        HistoryPage(_onlyBookmark, (page, size, onlyBookmark) async {
          return await Repository.rankFileKey14("score14 desc", page, size, star: onlyBookmark);
        }, key: Key('yuebang' + _onlyBookmark.toString())),
        HistoryPage(_onlyBookmark, (page, size, onlyBookmark) async {
          return await Repository.rankFileKey14("score60 desc", page, size, star: onlyBookmark);
        }, key: Key('jibang' + _onlyBookmark.toString())),
        HistoryPage(_onlyBookmark, (page, size, onlyBookmark) async {
          return Repository.historyFileKey(page, size + 1, star: onlyBookmark);
        }, key: Key("lishi" + _onlyBookmark.toString())),
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
          child: Icon(curBookmark),
          onPressed: _onChangeBookmark),
    );
  }
}
