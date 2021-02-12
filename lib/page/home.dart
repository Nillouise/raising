import 'package:flutter/material.dart';
import 'package:raising/page/FileList.dart';
import 'package:raising/page/rank.dart';

import 'category_page.dart';
import 'drawer.dart';

//此类相当稳定了
class RaisingHome extends StatelessWidget {
  RaisingHome({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> paths = List.of(["test", "fd", "tetes2", "test3"]);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
//          leading: Icon(
//            Icons.arrow_back,
//          ),
//          flexibleSpace: new Column(mainAxisAlignment: MainAxisAlignment.end, children: [
//            new TabBar(
//              tabs: [
//                Tab(text: "浏览"),
//                Tab(text: "排行榜"),
//                Tab(text: "分类"),
//              ],
//            ),
//          ]),
//          title: new Column(mainAxisAlignment: MainAxisAlignment.end, children: [
//            new TabBar(
//              tabs: [
//                Tab(text: "浏览"),
//                Tab(text: "排行榜"),
//                Tab(text: "分类"),
//              ],
//            ),
//          ]),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "current Title",
              ),
              Text(
                "path",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
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
