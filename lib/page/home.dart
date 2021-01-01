import 'package:flutter/material.dart';
import 'package:raising/page/FileList.dart';
import 'package:raising/page/rank.dart';

import 'category_page.dart';
import 'drawer.dart';

class RaisingHome extends StatelessWidget {
  RaisingHome({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
            flexibleSpace: new Column(mainAxisAlignment: MainAxisAlignment.end, children: [
          new TabBar(
            tabs: [
              Tab(text: "浏览"),
              Tab(text: "排行榜"),
              Tab(text: "分类"),
            ],
          ),
        ])),
        drawer: HomeDrawer(),
        body: TabBarView(
          children: [
            Center(child: ExplorerWidget()),
            Center(child: RankPage()),
            Center(child: CategoryPage()),
          ],
        ),
//          floatingActionButton: Draggable(
//              feedback: FloatingActionButton(child: Icon(Icons.drag_handle), onPressed: () {}),
//              child: FloatingActionButton(child: Icon(Icons.star), onPressed: () {}),
//              childWhenDragging: Container(),
//              onDragEnd: (details) => print(details.offset))
        // Here's the new attribute:

//        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
