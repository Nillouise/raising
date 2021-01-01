import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:raising/image/ExploreCO.dart';
import 'package:raising/image/ExploreFile.dart';

var logger = Logger();

/**
 * notify之后的_files数据不一定是最新的，因为本来就可能不会显示queryFiles里的file，比如说
 * 之后做一个功能，先选中host，再搜索，但这其实根本就不会需要awaitQueryFiles。
 */

class ExploreNavigator extends ChangeNotifier {
  ExploreFile exploreFile;
  String title;
  String absPath;
  List<ExploreCO> _files = List<ExploreCO>();

  List<ExploreCO> get files => _files;

  set files(List<ExploreCO> files) {
    _files = files;
  }

  void refresh(ExploreFile exploreFile, String absPath) async {
    this.exploreFile = exploreFile;
    this.absPath = absPath;
    notifyListeners();
  }

  void refreshPath(String absPath) {
    this.absPath = absPath;
    notifyListeners();
  }

  void setTitle(String title) {
    this.title = title;
  }

  Future<ExploreNavigator> awaitQueryFiles() async {
    List<ExploreCO> list = await exploreFile.queryFiles(absPath);
    files = list;
    return this;
  }

  bool isRoot() {
    return p.rootPrefix(absPath) == absPath && (absPath?.isEmpty ?? true);
    // return false;
  }

  bool isSelectHost() {
    return exploreFile != null;
  }
}
