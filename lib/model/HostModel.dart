import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:raising/dao/MetaPO.dart';

part 'HostModel.g.dart';

//此类还没能持久化到数据库

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
  void insert(HostPO host, {int index: 0}) {
    MetaPo.metaPo.hosts.insert(index, host);
    _uploadItems();
    notifyListeners();
  }

  UnmodifiableListView<HostPO> get hosts => UnmodifiableListView(MetaPo.metaPo.hosts);

  HostPO searchById(String id) {
    return MetaPo.metaPo.hosts.firstWhere((it) => it.id == id, orElse: () => null);
  }

  bool remove(int index) {
    if (index >= hosts.length) {
      return false;
    }
    MetaPo.metaPo.hosts.removeAt(index);
    _uploadItems();
    notifyListeners();
    return true;
  }

  bool replace(HostPO host) {
    int replaceIndex = MetaPo.metaPo.hosts.indexWhere((it) => it.id == host.id);
    if (replaceIndex == -1) {
      return false;
    }
    MetaPo.metaPo.hosts.replaceRange(replaceIndex, replaceIndex + 1, [host]);
    _uploadItems();
    notifyListeners();
    return true;
  }

  void _uploadItems() async {
    MetaPo.metaPo.hosts = MetaPo.metaPo.hosts;
    await MetaPo.save();
  }

  bool checkDuplicate(String nickName) {
    int index = MetaPo.metaPo.hosts.indexWhere((it) => it.nickName == nickName);
    return index != -1;
  }
}
