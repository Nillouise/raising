import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:raising/dao/MetaPO.dart';

part 'HostModel.g.dart';

@JsonSerializable()
class HostPO {
  String id;
  String nickName;
  String hostname; //maybe include the path
  String domain;
  String username;
  String password;
  String type; //用来标记是哪种服务器，转成对应的VO
  //不同的类使用不同的mixin即可
  factory HostPO.fromJson(Map<String, dynamic> json) => _$HostPOFromJson(json);

  Map<String, dynamic> toJson() => _$HostPOToJson(this);

  HostPO();
}

class WebDavHostVO extends HostPO {
  String get type {
    throw UnimplementedError("un support function");
  }
}

class HostModel extends ChangeNotifier {
  List<HostPO> _hosts;

  void insert(HostPO host, {int index: 0}) {
    _hosts.insert(index, host);
    _uploadItems();
    notifyListeners();
  }

  UnmodifiableListView<HostPO> get hosts => UnmodifiableListView(_hosts);

  HostPO searchById(String id) {
    return _hosts.firstWhere((it) => it.id == id, orElse: () => null);
  }

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
