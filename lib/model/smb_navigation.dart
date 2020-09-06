import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:raising/channel/Smb.dart';

import 'file_info.dart';

var logger = Logger();

class SmbNavigation extends ChangeNotifier {
  String _share;
  String _title;
  String _path;
  String _smbId;
  String smbNickName;
  List<FileInfo> _files;
  double scroll_speed;

  set title(value) {
    _title = value;
    notifyListeners();
  }

  set smbId(value) {
    _smbId = value;
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

  void refresh(BuildContext context, String share, String path, String smbId,
      String smbNickName) async {
//    var smb = Smb.getConfig(null);
//    List<FileInfo> list = await smb.listFiles(path, "*");
    _share = share;
    _title = path;
    _path = path;
    _smbId = smbId;
    this.smbNickName = smbNickName;
//    _files = list;
    notifyListeners();
  }

  Future<SmbNavigation> awaitSelf() async {
    var smb = Smb.getCurrentSmb();
    return smb.listFiles(_share, path, "*").then((value) {
      _files = value;
      return this;
    });
  }

  String get path => _path;

  String get share => _share;

  List<FileInfo> get files => _files;

  String get smbId => _smbId;
}
