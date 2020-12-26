import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:raising/image/ExploreCO.dart';
import 'package:raising/image/ExploreFile.dart';

import 'package:path/path.dart' as p;
var logger = Logger();

class ExploreNavigator extends ChangeNotifier {
  ExploreFile exploreFile;
  String title;
  String absPath;
  List<ExploreCO> files = List<ExploreCO>();

  void refresh(ExploreFile exploreFile, String absPath) async {
    this.exploreFile = exploreFile;
    this.absPath = absPath;
    awaitSelf();
    notifyListeners();
  }

  void refreshPath(String absPath) {
    absPath = absPath;
    awaitSelf();
    notifyListeners();
  }

  void refreshTitle(String title) {
    this.title = title;
    notifyListeners();
  }

  Future<bool> awaitSelf() async {
    List<ExploreCO> list = await exploreFile.queryFiles(absPath);
    files = list;
    return true;
  }

  bool isRoot(){
    return p.rootPrefix(absPath) == absPath && (absPath?.isEmpty ?? true);
    // return false;
  }

  bool isSelectHost(){
    return exploreFile != null;
  }


}
