import 'package:flutter/material.dart';
import 'package:raising/page/FileList.dart';
import 'package:raising/page/rank.dart';

import 'drawer.dart';

class RaisingHome extends StatelessWidget {
  RaisingHome({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: new Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              new TabBar(
                tabs: [
                  Tab(text: "浏览"),
                  Tab(text: "排行榜"),
                  Tab(text: "分类"),
                ],
              ),
            ]
          )
        ),

        drawer: HomeDrawer(),
        body: TabBarView(
          children: [
            Center(child: FileList()),
            Center(child: RankPage()),
            Center(child: RankPage()),
          ],
        ),
      ),
    );
  }
}




