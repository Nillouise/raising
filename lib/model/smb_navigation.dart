import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:raising/channel/Smb.dart';

import 'file_info.dart';

var logger = Logger();

class SmbNavigation extends ChangeNotifier {
  String _title;
  String _path;
  List<FileInfo> _files;

  set title(value) {
    _title = value;
    notifyListeners();
  }

  set path(value) {
    _path = value;
    notifyListeners();
  }

  set files(value) {
    _files = value;
    notifyListeners();
  }

  String get title => _title;

  void refresh(BuildContext context, String path) async {
//    var smb = Smb.getConfig(null);
//    List<FileInfo> list = await smb.listFiles(path, "*");
    _title = path;
    _path = path;
//    _files = list;
    notifyListeners();
  }

  Future<SmbNavigation> awaitSelf() async {
    var smb = Smb.getCurrentSmb();
    return smb.listFiles(path, "*").then((value) {
      _files = value;
      return this;
    });
  }

  String get path => _path;

  List<FileInfo> get files => _files;
}
