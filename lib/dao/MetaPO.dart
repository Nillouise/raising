// To parse this JSON data, do
//
//     final metaPo = metaPoFromJson(jsonString);

import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:raising/dao/Repository.dart';
/**
 * 使用https://app.quicktype.io/生成：
    {
    "key":"value",
    "fileKeyScoreChangeDay":"2018-09-06 15:03:48"
    }
 *
 *
 */
/**
 * 此类字段会频繁变动增加，应当用dart自带的命令进行更新，而且应当尽量贴合数据库，这样dart命令更新
 * 序列化类就不需要手动改.g文件了。
 */
MetaPo metaPoFromJson(String str) => MetaPo.fromJson(json.decode(str));

String metaPoToJson(MetaPo data) => json.encode(data.toJson());

class MetaPo {
  static MetaPo metaPo;

  MetaPo({
    this.key,
    this.fileKeyScoreChangeDay,
  });

  String key;
  DateTime fileKeyScoreChangeDay;
  List<SearchHistory> searchHistory;

  factory MetaPo.fromJson(Map<String, dynamic> json) => MetaPo(
        key: json["key"],
        fileKeyScoreChangeDay: DateTime.parse(json["fileKeyScoreChangeDay"]),
      );

  Map<String, dynamic> toJson() => {
        "key": key,
        "fileKeyScoreChangeDay": fileKeyScoreChangeDay.toIso8601String(),
      };

  static Future<void> load() async {
    MetaPo metaData = await Repository.getMetaData();
    metaPo = metaData;
  }

  static Future<void> save() async {
    await Repository.saveMetaData(metaPo);
  }
}

class SearchHistory {
  String keyword;
  DateTime searchTime;
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
