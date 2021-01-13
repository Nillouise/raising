import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/dao/SmbVO.dart';

//弃用还没处理完成
var logger = Logger();

class SmbListModel extends ChangeNotifier {
  List<SmbPO> _smbs;

  UnmodifiableListView<SmbPO> get smbs => UnmodifiableListView(_smbs);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  SmbListModel({List<SmbPO> smbs}) : _smbs = smbs ?? [];

  /// Loads remote data
  ///
  /// Call this initially and when the user manually refreshes
  Future loadTodos() {
    _isLoading = true;
    notifyListeners();

    return Repository.getAllSmbPO().then((loadedTodos) {
      _smbs.addAll(loadedTodos);
      _isLoading = false;
      notifyListeners();
    }).catchError((err) {
      _isLoading = false;
      notifyListeners();
    });
  }

  /// updates a [Todo] by replacing the item with the same id by the parameter [todo]
  void replaceSmb(SmbPO smb) {
    var oldTodo = _smbs.firstWhere((it) => it.id == smb.id);
    var replaceIndex = _smbs.indexOf(oldTodo);
    _smbs.replaceRange(replaceIndex, replaceIndex + 1, [smb]);
    _uploadItems();
    notifyListeners();
  }

  void removeSmb(String smbId) {
    _smbs.removeWhere((it) => it.id == smbId);
    _uploadItems();
    notifyListeners();
  }

  void addSmb(SmbPO todo) {
    _smbs.add(todo);
    _uploadItems();
    notifyListeners();
  }

  void _uploadItems() {
    Repository.deleteAllSmbPO().then((value) => Repository.insertSmbPO(_smbs));
//    Repository.getAllSmbPO().then((value) => Repository.deleteAllSmbPO()).then((value) => Repository.insertSmbPO(_smbs));

//    Repository.getAllSmbPO().then((value) => print(value[0].toJson()));
    //    Repository.deleteAllSmbPO();
//    Repository.insertSmbPO(_smbs);
  }

  SmbPO smbById(String id) {
    return _smbs.firstWhere((it) => it.id == id, orElse: () => null);
  }

  bool checkDuplicate(String id) {
    if (smbById(id) != null) {
      return true;
    } else {
      return false;
    }
  }
}
