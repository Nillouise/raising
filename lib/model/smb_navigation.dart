import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/SmbVO.dart';

var logger = Logger();

class SmbNavigation extends ChangeNotifier {
  String _title;
  SmbVO smbVO;
  List<DirectoryCO> _files;

  double scroll_speed;

  void refreshSmbPo(SmbPO po) async {
    smbVO = SmbVO.copyFromSmbPO(po);
    notifyListeners();
  }

  void refreshPath(String absPath){
    smbVO.absPath = absPath;
    notifyListeners();

  }



  void refreshTitle(String title) {
    _title = title;
    notifyListeners();
  }

  void refreshDirectoryInfo(List<DirectoryCO> files) {
    _files = files;
    notifyListeners();
  }

  Future<SmbNavigation> awaitSelf() async {
    return await SmbChannel.queryFiles(smbVO).then((value) {
      _files = value;
      return this;
    });
  }

  List<DirectoryCO> get files => _files;

  String get title => _title;
}
