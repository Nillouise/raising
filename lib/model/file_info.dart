import 'dart:async';
import 'dart:ffi';

import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/exception/DbException.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast/timestamp.dart';

part 'file_info.g.dart';

@JsonSerializable()
class FileKey {
  String filename; //唯一主键
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
  String smbNickName; //只用smbId可能无法恢复删除的smb链接
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

  List<Filter> getFinders() {
    List<Filter> finders = [];
    if (filename?.isNotEmpty ?? false) {
      finders.add(Filter.equals('filename', filename));
    }
    tags?.forEach((element) {
      finders.add(Filter.equals('tags', element, anyInList: true));
    });
    if (star != -1) {
      finders.add(Filter.equals('star', star));
    }
    partialFilenames?.forEach((element) {
      finders.add(Filter.matches('filename', ".*" + element + ".*"));
    });
    return finders;
  }
}

class FileRepository extends ChangeNotifier {
  static Database _cache_db;

  Database _db;

  void init() async {
    _db = await databaseFactoryIo.openDatabase((await getApplicationDocumentsDirectory()).path + "/sembast.db");
    _cache_db = _db;
    print(_db);
  }

  Future<List<FileInfo>> findFileKey(FileKey fileKey) async {
    var store = intMapStoreFactory.store('fileInfo');
    var finder = Finder(filter: Filter.equals('filename', fileKey.filename), sortOrders: [SortOrder('smbId')]);
    List<RecordSnapshot<int, Map<String, dynamic>>> records = (await store.find(_db, finder: finder));
  }

  Future<List<FileKey>> findFileKeyQuery(FileKeyQuery query) async {
    var store = intMapStoreFactory.store('fileInfo');
    var finder = Finder(filter: Filter.and(query.getFinders()), sortOrders: [SortOrder('smbId')]);
    List<RecordSnapshot<int, Map<String, dynamic>>> records = (await store.find(_db, finder: finder));
  }

  Future<List<FileInfo>> findByFilename(String filename) async {
    var store = intMapStoreFactory.store('fileInfo');
    var finder = Finder(filter: Filter.equals('filename', filename), sortOrders: [SortOrder('smbId')]);
    List<RecordSnapshot<int, Map<String, dynamic>>> records = (await store.find(_db, finder: finder));
  }

  Future<FileInfo> findByabsPath(String absPath, String smbId) async {
    var store = intMapStoreFactory.store('fileInfo');
    var finder = Finder(filter: Filter.and([Filter.equals('absPath', absPath), Filter.equals('smbId', smbId)]));
    RecordSnapshot<int, Map<String, dynamic>> records = (await store.findFirst(_db, finder: finder));

    if (records != null) {
      return FileInfo.fromJson(records.value);
    } else {
      return null;
    }
  }

  Future<bool> upsertFileInfo(String absPath, String smbId, String smbNickName,
      {String filename,
      DateTime updateTime,
      bool isDirectory,
      bool isCompressFile,
      int star,
      int readLenght,
      int length, //里面有多少文件
      int size //文件大小
      }) async {
    var finder = Finder(filter: Filter.and([Filter.equals("absPath", absPath), Filter.equals("smbId", smbId)]));

    Map<String, dynamic> updater = Map();
    updater["smbNickName"] = smbNickName;
    filename != null ? updater["filename"] = filename : null;
    updateTime != null ? updater["updateTime"] = updateTime : null;
    isDirectory != null ? updater["filename"] = isDirectory : null;
    isCompressFile != null ? updater["isCompressFile"] = isCompressFile : null;
    star != null ? updater["star"] = star : null;
    readLenght != null ? updater["readLenght"] = readLenght : null;
    length != null ? updater["length"] = length : null;
    size != null ? updater["size"] = size : null;

    var store = intMapStoreFactory.store('fileInfo');

    //利用事务+乐观锁实现非key的upsert效果。
    for (int i = 0; i < 3; i++) {
      try {
        await _db.transaction((txn) async {
          int updateCount = await store.update(txn, updater, finder: finder);
          if (updateCount == 0) {
            store.add(txn, {"absPath": absPath, "smbId": smbId});
            int doubelUpdateCount = await store.update(txn, updater, finder: finder);
            if (doubelUpdateCount != 1) {
              throw DbException("update conflict ${smbId} ${absPath}");
            }
          }
        });
        return true;
      } on DbException catch (e) {
        logger.e(e);
      }
    }
    return false;
  }

  Future<FileKey> upsertFileKey(
    String filename, {
    Map<String, String> tags,
    int star,
    DateTime clickTime,
    //应该根据阅读时间进行加成
    int increReadTime,
  }) async {
    Map<String, dynamic> updater = Map();
    tags != null ? updater["tags"] = tags : null;
    star != null ? updater["star"] = star : null;

    if ((clickTime == null && increReadTime != null) || (clickTime != null && increReadTime == null)) {
      throw DbException("clickTime and increReadTime should be together insert");
    }
    clickTime != null ? updater["clickTimes"] = List.of([Timestamp.fromDateTime(clickTime)]) : null;
    increReadTime != null ? updater["readTimes"] = List.of([increReadTime]) : null;

    var store = stringMapStoreFactory.store('fileKey');
    var put = await store.record(filename).put(_db, updater, merge: true);
    return FileKey.fromJson(put);
  }

  Future<bool> deleteFileKeyTag(String filename, String tag) {
    //TODO:
  }

  Future<FileKey> getFileKey(String filename) async {
    var store = stringMapStoreFactory.store('fileKey');
    Map<String, dynamic> fileKey = await store.record(filename).get(_db);
    if (fileKey != null) {
      return FileKey.fromJson(fileKey);
    } else {
      return null;
    }
  }

  static Future<Void> getAllInfo() async {
//    var store = stringMapStoreFactory.store('fileKey');
    List<RecordSnapshot<String, Map<String, dynamic>>> list = await stringMapStoreFactory.store('fileKey').find(_cache_db);
    List<RecordSnapshot<int, Map<String, dynamic>>> list2 = await intMapStoreFactory.store('fileInfo').find(_cache_db);
//    logger.d(list);
    logger.d("db info $list $list2");
  }
}
