import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class FileKey {
  String filename;
  Set<String> tags;
  int star;

  DateTime preOpenTime;
  DateTime preMonthOpenTime; //一个月前的最近点击
  DateTime preSeasonOpenTime; //一个季度前的最近点击
  int monthScore;
  int seasonScore;
  int yearScore;
}

class FileInfo {
  String smbId;
  String absPath;
  String filename;
  bool isDirectory;
  bool isCompressFile;
  FileKey fileKey;
  int star;

  //预设不会有子目录
  int readLenght; //已经看了多少页
  int length; //里面有多少文件
  int size; //文件大小

  String zipAbsPath;

  FileInfo(this.filename);
}

class ZipFileInfo {
  String smbId;
  String absPath;
  String zipAbsPath;
  int index;
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

  Future<List<Smb>> loadTodos() async {
    _db = await databaseFactoryIo.openDatabase(
        (await getApplicationDocumentsDirectory()).path + "/sembast.db");
    var store = intMapStoreFactory.store('smbManage');
    List<RecordSnapshot<int, Map<String, dynamic>>> records =
        (await store.find(_db));

    Iterable<Smb> map = records.map((element) {
      return Smb.fromJson(element.value);
    });
    return map.toList();
  }

  // Persists todos to local disk and the web
  Future save(List<Smb> smbs) async {
    var store = intMapStoreFactory.store('smbManage');

    await _db.transaction((txn) async {
      var i = (await store.delete(txn));
      logger.i("delete $i msg befor save successfule");
      await store.addAll(txn, smbs.map((e) => e.toJson()).toList());
    });
  }
}
