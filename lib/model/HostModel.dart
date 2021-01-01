import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:raising/dao/MetaPO.dart';

abstract class HostPO {
  String id;
  String nickName;
}

@JsonSerializable()
class WebdavHostPO extends HostPO {
  String hostname; // include the path
  String username;
  String password;
}

class HostModel extends ChangeNotifier {
  List<HostPO> _hosts;

  void insert(HostPO host, {int index: 0}) {
    _hosts.insert(index, host);
    _uploadItems();
    notifyListeners();
  }

  UnmodifiableListView<HostPO> get hosts => UnmodifiableListView(_hosts);

  bool remove(int index) {
    if (index >= hosts.length) {
      return false;
    }
    _hosts.removeAt(index);
    _uploadItems();
    notifyListeners();
    return true;
  }

  bool replace(HostPO host) {
    int replaceIndex = _hosts.indexWhere((it) => it.id == host.id);
    if (replaceIndex == -1) {
      return false;
    }
    _hosts.replaceRange(replaceIndex, replaceIndex + 1, [host]);
    _uploadItems();
    notifyListeners();
    return true;
  }

  void _uploadItems() async {
    MetaPo.metaPo.hosts = _hosts;
    await MetaPo.save();
  }

  bool checkDuplicate(String id) {
    int index = _hosts.indexWhere((it) => it.id == id);
    return index == -1;
  }
}
