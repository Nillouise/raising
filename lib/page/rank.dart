import 'package:flutter/material.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // 底部导航
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.filter_1), title: Text('月榜')),
          BottomNavigationBarItem(
              icon: Icon(Icons.filter_2), title: Text('季榜')),
          BottomNavigationBarItem(
              icon: Icon(Icons.filter_3), title: Text('年榜')),
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
