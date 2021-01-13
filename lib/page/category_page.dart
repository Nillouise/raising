import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/image/ExtractCO.dart';
import 'package:raising/model/smb_list_model.dart';

//此类目前基本还没进入开发进程，忽略
class CategoryPage extends StatefulWidget {
  CategoryPage({Key key}) : super(key: key);

  @override
  _CategoryPageState createState() {
    return _CategoryPageState();
  }
}

class _CategoryPageState extends State<CategoryPage> {
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

  var _controller = TextEditingController();
  bool _onlyBookmark = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: <Widget>[
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: "Enter a message",
            suffixIcon: IconButton(
              onPressed: () async {
                SmbListModel smbListModel = Provider.of<SmbListModel>(context, listen: false);
                SmbPO smb = smbListModel.smbById("loc##~##1605007610681");
//                Stream<List<DirectoryCO>> bfsFiles = SmbChannel.bfsFiles(SmbVO.copyFromSmbPO(smb));
                StreamSubscription<List<ExtractCO>> subscription;
                subscription = SmbChannel.bfsFiles(SmbVO.copyFromSmbPO(smb)).listen((event) {
                  event.forEach((element) {
                    print("current" + element.filename);
                  });
                  subscription.cancel();
                });
              },
              icon: Icon(Icons.clear),
            ),
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
          //悬浮按钮
          child: Icon(Icons.search),
          onPressed: _onChangeBookmark),
    );
  }
}
