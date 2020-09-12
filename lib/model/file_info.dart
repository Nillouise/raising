import 'dart:async';
import 'dart:ffi';

import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:raising/exception/DbException.dart';
import 'package:sqflite/sqflite.dart';

part 'file_info.g.dart';

@JsonSerializable()
class FileKey {
  String filename; //唯一索引，以后可能会加上md5之类的文件唯一标识
  Map<String, String> tags;
  int star;

  //什么时候点击了
  List<DateTime> clickTimes = new List<DateTime>();

  //按秒算，这次看了多少时间，应当跟clickTimes一起保存
  List<int> readTimes;

  FileKey(this.filename, this.tags, this.star, this.clickTimes, this.readTimes);

  factory FileKey.fromJson(Map<String, dynamic> json) =>
      _$FileKeyFromJson(json);

  Map<String, dynamic> toJson() => _$FileKeyToJson(this);
}

@JsonSerializable()
class ZipFileContent {
  String absFilename;
  String zipFilename;
  int index;
  int length;
  dynamic content;

  ZipFileContent(this.absFilename, this.zipFilename, this.index, this.length,
      this.content);

  ZipFileContent.content(this.content);

  factory ZipFileContent.fromJson(Map<String, dynamic> json) =>
      _$ZipFileContentFromJson(json);

  Map<String, dynamic> toJson() => _$ZipFileContentToJson(this);
}

@JsonSerializable()
class SmbHalfResult {
  String msg;
  Map<int, ZipFileContent> result;

  SmbHalfResult(this.msg, this.result);

  factory SmbHalfResult.fromJson(Map<String, dynamic> json) =>
      _$SmbHalfResultFromJson(json);

  Map<String, dynamic> toJson() => _$SmbHalfResultToJson(this);
}

class FileRepository extends ChangeNotifier {
  static Database _cache_db;

  Database _db;

  void init() async {
    String filename; //唯一主键
    Map<String, String> tags;
    int star;

    //什么时候点击了
    List<DateTime> clickTimes = new List<DateTime>();

    //按秒算，这次看了多少时间，应当跟clickTimes一起保存
    List<int> readTimes;

    _db = await openDatabase(
        (await getApplicationDocumentsDirectory()).path + "/raising.sqflite");
    _cache_db = _db;
    print(_db);
  }

  static Future<Void> getAllInfo() async {
    // Insert some records in a transaction
    List<Map<String, dynamic>> list = await _cache_db.transaction((txn) async {
      List<Map<String, dynamic>> lst = new List();
      lst.addAll(await txn.query("file_key"));
      lst.addAll(await txn.query("file_key_clicks"));
      lst.addAll(await txn.query("file_key_tags"));
      lst.addAll(await txn.query("smb_manage"));
      lst.addAll(await txn.query("file_info"));
      return lst;
    });
//    logger.d(list);
//    logger.d("db info $list");
  }
}
