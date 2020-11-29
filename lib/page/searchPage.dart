import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/constant/Constant.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/MetaPO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/model/smb_navigation.dart';

import '../util.dart';
import 'FileList.dart';
import 'viewer.dart';

class SearchPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SearchPageState();
  }

  SearchPage();
}

class _SearchPageState extends State<SearchPage> {
  var _controller = TextEditingController();
  List<SearchingCO> directorys = List();
  bool isSearching = false;
  String searchingText = "searching";

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
//                directorys.clear();
                setState(() {
                  isSearching = true;
                });
                SmbNavigation smbNavigation = Provider.of<SmbNavigation>(context, listen: false);
                SmbPO smb = smbNavigation.smbVO;
                StreamSubscription<List<SearchingCO>> subscription;
                subscription = SmbChannel.searchFiles(SmbVO.copyFromSmbPO(smb), _controller.value.text).listen((event) {
//                  event.forEach((element) {
////                    print("current" + element.filename);
//                  directorys.add()
//                  });
                  if (event != null && event.length > 0)
                    setState(() {
                      searchingText = event[0].directoryCO.filename;
                      directorys.addAll(event);
                    });
                });
                subscription.onDone(() {
                  setState(() {
                    searchingText = "";
                    isSearching = false;
                  });
                });
              },
              icon: Icon(Icons.search),
            ),
          ),
        )),
        body: Column(
          children: <Widget>[
            ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: double.infinity, //宽度尽可能大
                    minHeight: 60.0 //最小高度为50像素
                    ),
                child: Text(searchingText)),

//            Container(
//              child: Text(searchingText),
//            ),
            SearchResult(directorys)
          ],
        ));
  }
}

class SearchResult extends StatefulWidget {
  final List<SearchingCO> directorys;

  SearchResult(this.directorys);

  @override
  State<StatefulWidget> createState() {
    return SearchResultState();
  }
}

class SearchResultState extends State<SearchResult> {
  @override
  Widget build(BuildContext context) {
    //TODO:这里有个引起PreviewFile刷新的功能没搞定，应该是因为directorys重新插入，然后被重新build了导致的
    return Expanded(
        child: ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: widget.directorys.length,
            itemBuilder: (context, index) {
              final item = widget.directorys[index];
//                      return ListTile(title: Text('${item.directoryCO.filename}'), trailing: Icon(Icons.remove), onTap: () {});
              return ListTile(
                leading: AspectRatio(aspectRatio: 1, child: PreviewFile(item.directoryCO, item.smbVO)),
                title: Text(item.directoryCO.filename),
                onTap: () {
                  if (item.directoryCO.isDirectory) {
//                            catalog.refreshPath(Utils.joinPath(catalog._smb.absPath, files[index].filename));
                  } else if (Constants.COMPRESS_AND_IMAGE_FILE.contains(p.extension(item.directoryCO.filename))) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FutureViewerChecker(0, Utils.joinPath(item.smbVO.absPath, item.directoryCO.filename), List())),
                    );
                  }
                },
              );
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
