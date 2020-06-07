import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:raising/channel/Smb.dart';

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';


enum VisibilityFilter { all, active, completed }

class SmbRepository {
  /// Loads todos first from File storage. If they don't exist or encounter an
  /// error, it attempts to load the Todos from a Web Client.
  Future<List<Smb>> loadTodos() async {
    final db = await databaseFactoryIo
        .openDatabase("sembast.db");
    var store = intMapStoreFactory.store('smbManage');

    var key = await store.add(db, {'name': 'ugly'});
    var record = await store.record(key).getSnapshot(db);
    record =
        (await store.find(db, finder: Finder(filter: Filter.byKey(record.key))))
            .first;
    print(record);
    var records = (await store.find(db,
        finder: Finder(filter: Filter.matches('name', '^ugly'))));
    return Smb.smbMap.values.toList();
  }

  // Persists todos to local disk and the web
  Future saveTodos(List<Smb> smbs) async {
    Smb.smbMap.clear();
    smbs.map((x) {
      Smb.smbMap[x.id] = x;
    });
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
  void updateTodo(Smb todo) {
    assert(todo != null);
    assert(todo.id != null);
    var oldTodo = _smbs.firstWhere((it) => it.id == todo.id);
    var replaceIndex = _smbs.indexOf(oldTodo);
    _smbs.replaceRange(replaceIndex, replaceIndex + 1, [todo]);
    notifyListeners();
    _uploadItems();
  }

  void removeTodo(Smb todo) {
    _smbs.removeWhere((it) => it.id == todo.id);
    notifyListeners();
    _uploadItems();
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
    repository.saveTodos(_smbs);
  }

  Smb smbById(String id) {
    return _smbs.firstWhere((it) => it.id == id, orElse: () => null);
  }
}
