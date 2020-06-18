import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

part 'file_info.g.dart';

@JsonSerializable()
class FileKey {
  String filename; //唯一主键
  Set<String> tags;
  int star;

  DateTime preOpenTime; //最近一次点击
  DateTime preMonthOpenTime; //一个月前的最近点击
  DateTime preSeasonOpenTime; //一个季度前的最近点击
  //应该根据阅读时间进行加成
  int monthScore;
  int seasonScore;
  int yearScore;

  FileKey(
      this.filename,
      this.tags,
      this.star,
      this.preOpenTime,
      this.preMonthOpenTime,
      this.preSeasonOpenTime,
      this.monthScore,
      this.seasonScore,
      this.yearScore);

  factory FileKey.fromJson(Map<String, dynamic> json) =>
      _$FileKeyFromJson(json);

  Map<String, dynamic> toJson() => _$FileKeyToJson(this);
}

@JsonSerializable()
class ZipFileContent {
  String filename;
  String zipFilename;
  int index;
  int length;
  dynamic content;

  ZipFileContent(
      this.filename, this.zipFilename, this.index, this.length, this.content);

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

@JsonSerializable()
class FileInfo {
  //smbId跟absPath组成一个唯一主键
  String smbId;
  String absPath;
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

  FileInfo(this.filename);

  factory FileInfo.fromJson(Map<String, dynamic> json) =>
      _$FileInfoFromJson(json);

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

class FileRepository {
  Database _db;

  void init() async {
    _db = await databaseFactoryIo.openDatabase(
        (await getApplicationDocumentsDirectory()).path + "/sembast.db");
  }

  Future<List<FileInfo>> findFileKey(FileKey fileKey) async {
    var store = stringMapStoreFactory.store('fileInfo');
    var finder = Finder(
        filter: Filter.equals('filename', fileKey.filename),
        sortOrders: [SortOrder('smbId')]);
    List<RecordSnapshot<String, Map<String, dynamic>>> records =
        (await store.find(_db, finder: finder));
  }

  Future<List<FileKey>> findFileKeyQuery(FileKeyQuery query) async {
    var store = stringMapStoreFactory.store('fileInfo');
    var finder = Finder(
        filter: Filter.and(query.getFinders()),
        sortOrders: [SortOrder('smbId')]);
    List<RecordSnapshot<String, Map<String, dynamic>>> records =
        (await store.find(_db, finder: finder));
  }

  Future<List<FileInfo>> findByFilename(String filename) async {
    var store = stringMapStoreFactory.store('fileInfo');
    var finder = Finder(
        filter: Filter.equals('filename', filename),
        sortOrders: [SortOrder('smbId')]);
    List<RecordSnapshot<String, Map<String, dynamic>>> records =
        (await store.find(_db, finder: finder));
  }

  Future addFileKey(FileKey fileKey) {}

  Future<FileKey> getFileKey(String filename) {}
}
