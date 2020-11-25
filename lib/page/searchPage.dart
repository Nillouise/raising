import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/MetaPO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/model/smb_navigation.dart';

class SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }

  SearchPage();
}

class _SearchPageState extends State<SearchPage> {
  var _controller = TextEditingController();
  List<DirectoryCO> directorys = List();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: "Enter a keyword",
            suffixIcon: IconButton(
              onPressed: () async {
                SmbNavigation smbNavigation = Provider.of<SmbNavigation>(context, listen: false);
                SmbPO smb = smbNavigation.smbVO;
                StreamSubscription<List<DirectoryCO>> subscription;
                subscription = SmbChannel.searchFiles(SmbVO.copyFromSmbPO(smb), _controller.value.text).listen((event) {
//                  event.forEach((element) {
////                    print("current" + element.filename);
//                  directorys.add()
//                  });
                  if (event != null && event.length > 0)
                    setState(() {
                      directorys.addAll(event);
                    });
                });
              },
              icon: Icon(Icons.search),
            ),
          ),
        )),
        body: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: directorys.length,
            itemBuilder: (context, index) {
              final item = directorys[index];
              return ListTile(title: Text('${item.filename}'), trailing: Icon(Icons.remove), onTap: () {});
            }));
  }
}

class HistorySearchList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SearchHistoryModel searchHistoryModel = Provider.of<SearchHistoryModel>(context, listen: false);
    List<SearchHistory> history = searchHistoryModel.get();
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: history.length,
        itemBuilder: (context, index) {
          final item = history[index];
          return ListTile(title: Text('${item.keyword}'), trailing: Icon(Icons.remove), onTap: () {});
        });
  }
}
