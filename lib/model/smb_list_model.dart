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
    _db = await openDatabase((await getApplicationDocumentsDirectory()).path + "/sqllite.db", version: 1, onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE smb_manage (id INTEGER PRIMARY KEY, _nickName TEXT, hostname TEXT, hostname TEXT,domain TEXT,username TEXT,password TEXT)");
    });
    List<Map<String, dynamic>> list = await _db.rawQuery('SELECT * FROM file_key');
    return list.map((e) => Smb.fromJson(e)).toList();
  }

  // Persists todos to local disk and the web
  Future save(List<Smb> smbs) async {
    await _db.transaction((txn) async {
      txn.delete("smb_manage");
      smbs.forEach((element) {
        txn.insert("smb_manage", element.toJson());
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
