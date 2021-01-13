// To parse this JSON data, do
//
//     final metaPo = metaPoFromJson(jsonString);

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:raising/common/JsonConverter.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/model/HostModel.dart';

part 'MetaPO.g.dart';

//代码设计未完成，这个po还没能存到数据库

/**
 * 使用https://app.quicktype.io/生成：
    {
    "key":"value",
    "fileKeyScoreChangeDay":"2018-09-06 15:03:48"
    }
 */
/**
 * 此类字段会频繁变动增加，应当用dart自带的命令进行更新，而且应当尽量贴合数据库，这样dart命令更新
 * 序列化类就不需要手动改.g文件了。
 */
@JsonSerializable()
@CustomDateTimeConverter()
class MetaPo {
  static MetaPo metaPo;

  MetaPo();

  String key = "MetaPo";
  DateTime fileKeyScoreChangeDay;
  List<SearchHistory> searchHistory = List();
  List<HostPO> hosts = List();

  //不同的类使用不同的mixin即可
  factory MetaPo.fromJson(Map<String, dynamic> json) => _$MetaPoFromJson(json);

  Map<String, dynamic> toJson() => _$MetaPoToJson(this);

  static Future<MetaPo> load() async {
    MetaPo metaData = await Repository.getMetaData();
    metaPo = metaData;
    if (metaPo.key == null) {
      metaPo.key = "MetaPo";
    }

    if (metaPo.fileKeyScoreChangeDay == null) {
      metaPo.fileKeyScoreChangeDay = DateTime.now();
    }

    return metaPo;
  }

  static Future<void> save() async {
    await Repository.saveMetaData(metaPo);
  }
}

@JsonSerializable()
@CustomDateTimeConverter()
class SearchHistory {
  String keyword;
  DateTime searchTime;

  SearchHistory(this.keyword, this.searchTime); //不同的类使用不同的mixin即可

  factory SearchHistory.fromJson(Map<String, dynamic> json) => _$SearchHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$SearchHistoryToJson(this);
}

class SearchHistoryModel extends ChangeNotifier {
  List<SearchHistory> get() {
    if (MetaPo.metaPo.searchHistory == null) {
      MetaPo.metaPo.searchHistory = List();
    }
    return MetaPo.metaPo.searchHistory;
  }

  void set(List<SearchHistory> history) {
    MetaPo.metaPo.searchHistory = history;
    updateStatus();
  }

  void updateStatus() {
    notifyListeners();
  }

  void insert(SearchHistory history) {
    delete(history);
    MetaPo.metaPo.searchHistory.insert(0, history);
    set(MetaPo.metaPo.searchHistory);
  }

  void delete(SearchHistory history) {
    MetaPo.metaPo.searchHistory.removeWhere((element) => element.keyword == history.keyword);
    set(MetaPo.metaPo.searchHistory);
  }
}
