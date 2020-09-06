import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:sqflite/sqflite.dart';

var logger = Logger();

class SmbRepository {
  Database _db;

  /// Loads todos first from File storage. If they don't exist or encounter an
  /// error, it attempts to load the Todos from a Web Client.
  Future<List<Smb>> loadTodos() async {
    _db = await openDatabase(
        (await getApplicationDocumentsDirectory()).path + "/raising.sqflite",
        version: 2, onCreate: (Database db, int version) async {
      await db.execute(
          "CREATE TABLE smb_manage (id TEXT PRIMARY KEY, realNickName TEXT, hostname TEXT,domain TEXT,username TEXT,password TEXT)");

      await db.execute(
          "CREATE TABLE file_key (filename TEXT PRIMARY KEY, star INTEGER)");
      await db.execute(
          "CREATE TABLE file_key_clicks (id INTEGER PRIMARY KEY, filename TEXT, clickTime INTEGER, readTime INTEGER)");
      await db.execute(
          "CREATE INDEX file_key_clicks_index ON file_key_clicks(filename)");
      await db.execute(
          "CREATE TABLE file_key_tags (id INTEGER PRIMARY KEY, filename TEXT, tag TEXT)");
      await db.execute(
          "CREATE INDEX file_key_tags_index ON file_key_tags(filename)");

      //File info
      await db.execute(
          "CREATE TABLE file_info (id INTEGER PRIMARY KEY,smbId TEXT,smbNickName TEXT,absPath TEXT, filename TEXT, updateTime INTEGER, isDirectory INTEGER, isCompressFile INTEGER, readLenght INTEGER, lenght INTEGER, size INTEGER)");
      await db.execute(
          "CREATE UNIQUE INDEX file_info_index ON file_info(smbId, absPath)");
    });
    List<Map<String, dynamic>> list =
        await _db.rawQuery('SELECT * FROM smb_manage');
    return list.map((e) => Smb.fromJson(e)).toList();
  }

  // Persists todos to local disk and the web
  Future save(List<Smb> smbs) async {
    await _db.transaction((txn) async {
      txn.delete("smb_manage");
      smbs.forEach((e) {
//        txn.insert("insert into smb_manage", e.toJson());
        txn.rawInsert(
            "insert into smb_manage(id, realNickName, hostname, domain, username, password) values(?,?,?,?,?)",
            [
              e.id,
              e.realNickName,
              e.hostname,
              e.domain,
              e.username,
              e.password
            ]);
      });
    });

//    var store = intMapStoreFactory.store('smbManage');
//
//    await _db.transaction((txn) async {
//      var i = (await store.delete(txn));
//      logger.i("delete $i msg befor save successfule");
//      await store.addAll(txn, smbs.map((e) => e.toJson()).toList());
//    });

//    Smb.smbMap.clear();
//    smbs.map((x) {
//      Smb.smbMap[x.id] = x;
//    });
  }
}

class SmbListModel extends ChangeNotifier {
  SmbRepository repository = SmbRepository();

  List<Smb> _smbs;

  UnmodifiableListView<Smb> get smbs => UnmodifiableListView(_smbs);

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  SmbListModel({List<Smb> smbs}) : _smbs = smbs ?? [];

  /// Loads remote data
  ///
  /// Call this initially and when the user manually refreshes
  Future loadTodos() {
    _isLoading = true;
    notifyListeners();

    return repository.loadTodos().then((loadedTodos) {
      _smbs.addAll(loadedTodos);
      _isLoading = false;
      notifyListeners();
    }).catchError((err) {
      _isLoading = false;
      notifyListeners();
    });
  }

  /// updates a [Todo] by replacing the item with the same id by the parameter [todo]
  void replaceSmb(Smb smb) {
    var oldTodo = _smbs.firstWhere((it) => it.id == smb.id);
    var replaceIndex = _smbs.indexOf(oldTodo);
    _smbs.replaceRange(replaceIndex, replaceIndex + 1, [smb]);
    _uploadItems();
    notifyListeners();
  }

  void removeSmb(String smbId) {
    _smbs.removeWhere((it) => it.id == smbId);
    notifyListeners();
    _uploadItems();
  }

  void addSmb(Smb todo) {
    _smbs.add(todo);
    notifyListeners();
    _uploadItems();
  }

  void _uploadItems() {
    repository.save(_smbs);
  }

  Smb smbById(String id) {
    return _smbs.firstWhere((it) => it.id == id, orElse: () => null);
  }

  bool checkDuplicate(String id) {
    if (smbById(id) != null) {
      return true;
    } else {
      return false;
    }
  }
}
