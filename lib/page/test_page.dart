import 'package:flutter/material.dart';
import 'package:raising/page/FileList.dart';
import 'package:raising/page/rank.dart';

import 'category_page.dart';
import 'drawer.dart';

class TestPage extends StatelessWidget {
  TestPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        FlatButton(
          onPressed: () {
            print("press flat button");
          },
          child: Text(
            "Flat Button",
            style: TextStyle(fontSize: 20.0),
          ),
        )
      ],
    ));
  }
}
