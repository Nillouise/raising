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

  factory FileKey.fromJson(Map<String, dynamic> json) => _$FileKeyFromJson(json);

  Map<String, dynamic> toJson() => _$FileKeyToJson(this);
}

@JsonSerializable()
class ZipFileContent {
  String absFilename;
  String zipFilename;
  int index;
  int length;
  dynamic content;

  ZipFileContent(this.absFilename, this.zipFilename, this.index, this.length, this.content);

  ZipFileContent.content(this.content);

  factory ZipFileContent.fromJson(Map<String, dynamic> json) => _$ZipFileContentFromJson(json);

  Map<String, dynamic> toJson() => _$ZipFileContentToJson(this);
}

@JsonSerializable()
class SmbHalfResult {
  String msg;
  Map<int, ZipFileContent> result;

  SmbHalfResult(this.msg, this.result);

  factory SmbHalfResult.fromJson(Map<String, dynamic> json) => _$SmbHalfResultFromJson(json);

  Map<String, dynamic> toJson() => _$SmbHalfResultToJson(this);
}

@JsonSerializable()
class FileInfo {
  //smbId跟absPath组成一个唯一主键
  String smbId;
  String smbNickName; //只用smbId可能无法恢复删除的smb链接,所以也存储一下这个nickName
  String absPath; //path 包括文件名合smbNickName
  String filename;
  DateTime updateTime;
  bool isDirectory;
  bool isCompressFile;
  FileKey fileKey;
  int star;

  //预设压缩文件下不会有子目录
  int readLenght; //已经看了多少页
  int length; //里面有多少文件
  int size; //文件大小

  FileInfo();

  factory FileInfo.fromJson(Map<String, dynamic> json) => _$FileInfoFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoToJson(this);
}

class ZipFileInfo {
  //smbId跟absPath、zipAbsPath或index组成一个唯一主键
  String smbId;

  //压缩文件的绝对路径
  String absPath;

  //压缩文件名
  String filename;

  //解压文件名
  String zipAbsPath;
  int index;
}

class FileKeyQuery {
  String filename; //empty for all
  Set<String> tags; //empty for all
  int star = -1; //-1 for all
  Set<String> partialFilenames; //find by partial filename

//  List<Filter> getFinders() {
//    List<Filter> finders = [];
//    if (filename?.isNotEmpty ?? false) {
//      finders.add(Filter.equals('filename', filename));
//    }
//    tags?.forEach((element) {
//      finders.add(Filter.equals('tags', element, anyInList: true));
//    });
//    if (star != -1) {
//      finders.add(Filter.equals('star', star));
//    }
//    partialFilenames?.forEach((element) {
//      finders.add(Filter.matches('filename', ".*" + element + ".*"));
//    });
//    return finders;
//  }
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

    _db = await openDatabase((await getApplicationDocumentsDirectory()).path + "/raising.sqflite");
    _cache_db = _db;
    print(_db);
  }

  Future<Void> upsertFileKey(
    String filename, {
    String tag,
    int star,
    DateTime clickTime,
    //应该根据阅读时间进行加成
    int increReadTime,
  }) async {
    // Insert some records in a transaction
    await _db.transaction((txn) async {
      List<Map> maps = await txn.query("file_key", where: 'filename = ?', whereArgs: [filename]);
      if (maps.length == 0) {
        if (star == null) {
          star = 0;
        }
        txn.rawInsert("insert into file_key(filename,star) values(?,?)", [filename, star]);
      } else {
        if (star != null) {
          txn.update("file_key", {"star": star}, where: 'filename = ?', whereArgs: [filename]);
        }
      }

      if ((clickTime == null && increReadTime != null) || (clickTime != null && increReadTime == null)) {
        throw DbException("clickTime and increReadTime should be together insert");
      }
      if (clickTime != null && increReadTime != null) {
        txn.rawInsert("insert into file_key_clicks(filename,clickTime,readTime) values(?,?,?)", [filename, clickTime.millisecondsSinceEpoch, increReadTime]);
      }
      if (tag != null) {
        txn.rawInsert("insert into file_key_tags(filename,tag) values(?,?)", [filename, tag]);
      }
    });

    notifyListeners();
  }

  Future<bool> deleteFileKeyTag(String filename, String tag) {
    //TODO:
  }

  Future<FileKey> getFileKey(String filename) async {
    List<Map<String, dynamic>> list = await _db.rawQuery('SELECT * FROM file_key');
    if (list.length > 0) {
      return FileKey.fromJson(list[0]);
    } else {
      return null;
    }
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
