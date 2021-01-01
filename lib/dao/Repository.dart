import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/MetaPO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/rank/rankAlgorithm.dart';
import 'package:sqflite/sqflite.dart';

class Repository {
  static Database _cache_db;

  static Database _db;

  static Database get db => _db;

  static Future<void> init() async {
    _db = await openDatabase((await getApplicationDocumentsDirectory()).path + "/sqlit3.db", version: 1, onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE meta_data (keyname TEXT PRIMARY KEY, content TEXT)");

      await db.execute("CREATE TABLE smb_manage (id TEXT PRIMARY KEY, _nickName TEXT, hostname TEXT,domain TEXT,username TEXT,password TEXT)");

      await db.execute("CREATE TABLE cache (cacheKey TEXT PRIMARY KEY, content Text)");

      //TODO:处理一下recentReadTime
      await db.execute("CREATE TABLE file_key (filename TEXT PRIMARY KEY, star INTEGER, recentReadTime INTEGER, score14 REAL, score60 REAL)");
      await db.execute("CREATE INDEX score14_index ON file_key(score14)");
      await db.execute("CREATE INDEX score60_index ON file_key(score60)");

      await db.execute("CREATE TABLE file_key_clicks (id INTEGER PRIMARY KEY, filename TEXT, clickTime INTEGER, readTime INTEGER)");
      await db.execute("CREATE INDEX file_key_clicks_index ON file_key_clicks(filename)");
      await db.execute("CREATE TABLE file_key_tags (id INTEGER PRIMARY KEY, filename TEXT, tag TEXT)");
      await db.execute("CREATE INDEX file_key_tags_index ON file_key_tags(filename)");

      await db.execute(
          "CREATE TABLE file_info (id INTEGER PRIMARY KEY,smbId TEXT,smbNickName TEXT,absPath TEXT, filename TEXT, updateTime INTEGER, isDirectory INTEGER, isShare INTEGER, isCompressFile INTEGER, readLenght INTEGER, fileNum INTEGER, size INTEGER, recentReadTime INTEGER)");
      await db.execute("CREATE UNIQUE INDEX file_info_index ON file_info(smbId, absPath)");
    });

    _cache_db = _db;
    print(_db);
  }

  static Future<List<FileKeyPO>> rankFileKey14(String orderBy, int page, int size, {bool star = false}) async {
    List<Map<String, dynamic>> list = await _db.query("file_key", where: star ? "star > 0" : null, orderBy: orderBy, offset: page * size, limit: size);
    return list.map((e) => FileKeyPO.fromJson(e)).toList();
  }

  static Future<List<FileInfoPO>> historyFileInfo(int page, int size, {String orderBy = "recentReadTime desc", bool star = false}) async {
    try {
      String whereState = "recentReadTime IS NOT NULL" + (star ? "AND star > 0" : "");
      List<Map<String, dynamic>> list = await _db.query("file_info", where: whereState, orderBy: orderBy, offset: page * size, limit: size);
      return list.map((e) => FileInfoPO.fromJson(e)).toList();
    } catch (e) {
      logger.e(e);
    }
  }

  static clearHistoryFileInfo() async {
    await _db.transaction((txn) async {
      txn.rawUpdate("UPDATE file_info set recentReadTime = null");
    });
  }

//  static Future<List<FileKeyPO>> rankFileKey60(int page, int size) async {
//    List<Map<String, dynamic>> list = await _db.rawQuery('SELECT * FROM file_key sort by score60 desc limit ? offset ?', [size, page * size]);
//    return list.map((e) => FileKeyPO.fromJson(e)).toList();
//  }
//
//  static Future<List<FileKeyPO>> rankFileKeyHistory(int page, int size) async {
//    List<Map<String, dynamic>> list = await _db.rawQuery('SELECT * FROM file_key sort by recentReadTime desc limit ? offset ?', [size, page * size]);
//    return list.map((e) => FileKeyPO.fromJson(e)).toList();
//  }

  static Future<MetaPo> getMetaData() async {
    List<Map<String, dynamic>> list = await _db.transaction((txn) async {
      return await txn.rawQuery("select * from meta_data");
    });
    var res = list.map((e) => MetaPo.fromJson(json.decode(e["content"]))).toList();
    if (res.isEmpty) {
      return MetaPo();
    }
    return res[0];
  }

  static Future saveMetaData(MetaPo po) async {
    await _db.transaction((txn) async {
      return await txn.insert("meta_data", {"keyname": po.key, "content": json.encode(po.toJson())}, conflictAlgorithm: ConflictAlgorithm.replace);
    });
  }

  static Future<List<SmbPO>> getAllSmbPO() async {
    try {
      List<Map<String, dynamic>> list = await _db.transaction((txn) async {
        var res = await txn.rawQuery(
          "select * from smb_manage",
        );
        return res;
      });
      return list.map((e) => SmbPO.fromJson(e)).toList();
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }

  static Future<void> deleteAllSmbPO() async {
    await _db.transaction((txn) async {
      return await txn.rawQuery(
        "delete from smb_manage",
      );
    });
  }

  static Future<void> insertSmbPO(List<SmbPO> lst) async {
    var list = await getAllSmbPO();
    await _db.transaction((txn) async {
      lst.forEach((element) {
        txn.insert("smb_manage", element.toJson());
      });
    });
  }

  static Future<FileInfoPO> findByabsPath(String absPath, String smbId) async {
    List<Map<String, dynamic>> list = await _db.transaction((txn) async {
      return await txn.rawQuery("select * from file_info where smbId=? and absPath=?", [smbId, absPath]);
    });
    if (list.length > 0) {
      return FileInfoPO.fromJson(list[0]);
    } else {
      return null;
    }
  }

  static Future<bool> upsertFileInfo(String absPath, String smbId, String smbNickName, FileInfoPO fileinfo) async {
    fileinfo
      ..absPath = absPath
      ..smbId = smbId
      ..smbNickName = smbNickName
      ..recentReadTime = DateTime.now();
    var json = fileinfo.toJson();
    json.removeWhere((key, value) => key == null || value == null);
    int res = await _db.transaction((txn) async {
      if ((await txn.query("file_info", where: "smbId=? and absPath=?", whereArgs: [smbId, absPath])).length == 0) {
        return await txn.insert("file_info", json);
      } else {
        return await txn.update("file_info", json, where: "smbId=? and absPath=?", whereArgs: [smbId, absPath]);
      }
    });
    return res > 0;
  }

  //把所有Score14除以x，在存到数据库
  static Future<Void> minFileKeyScore14(double x) async {
    await _db.transaction((txn) async {
      txn.rawUpdate("UPDATE file_key set score14 = score14/?", [x]);
    });
  }

  //把所有Score60除以x，在存到数据库
  static Future<Void> minFileKeyScore60(double x) async {
    await _db.transaction((txn) async {
      txn.rawUpdate("UPDATE file_key set score60 = score60 / ?  ", [x]);
    });
  }

  static String randString() {
    const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();

    return String.fromCharCodes(Iterable.generate(6, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  //把所有Score除以x，在存到数据库
  static Future<Void> testInsertFileKeyScore() async {
    Stopwatch stopwatch = new Stopwatch()..start();
//    minFileKeyScore(2.1);
    print('doSomething() executed in ${stopwatch.elapsed}');
    // Insert some records in a transaction
    await _db.transaction((txn) async {
//      for (int i = 0; i < 20000; i++) {
//        await txn.rawInsert("insert into file_key(filename,star,score14,score60) values(?,?,?,?)", ["file" + randString() + i.toString(), 5, 1000.0, 2000.0]);
//      }
      var rawQuery = await txn.rawQuery("select * from file_key order by score14 desc limit 1000 ");

      print('doSomething() executed in ${stopwatch.elapsed}');
      print(rawQuery);
    });
    print("testInsertFileKeyScore complete");
  }

  static Future<Void> upsertFileKey(
    String filename, {
    String tag,
    int star,
    DateTime recentReadTime,
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
//        txn.rawInsert("insert into file_key(filename,star, score14, score60) values(?,?,?,?)",
//            [filename, star, getScoreByReadTime(increReadTime, true), getScoreByReadTime(increReadTime, true)]);
        txn.insert("file_key", {
          "filename": filename,
          "star": star,
          "recentReadTime": recentReadTime.millisecondsSinceEpoch,
          "score14": getScoreByReadTime(increReadTime, true),
          "score60": getScoreByReadTime(increReadTime, true)
        });
      } else {
        if (star != null) {
//          txn.update("file_key", {"star": star}, where: 'filename = ?', whereArgs: [filename]);
          txn.update("file_key",
              {"star": star, "score14": maps[0]["score14"] + getScoreByReadTime(increReadTime, false), "score60": maps[0]["score60"] + getScoreByReadTime(increReadTime, false)},
              where: 'filename = ?', whereArgs: [filename]);
        }
      }

      if (tag != null) {
        txn.rawInsert("insert into file_key_tags(filename,tag) values(?,?)", [filename, tag]);
      }
    });
  }

  static Future<bool> deleteFileKeyTag(String filename, String tag) {
    //TODO:
  }

  static Future<FileKeyPO> getFileKey(String filename) async {
//    List<Map<String, dynamic>> list = await _db.rawQuery('SELECT * FROM file_key');
    List<Map<String, dynamic>> list = await _db.rawQuery('SELECT * FROM file_key where filename = ?', [filename]);
    if (list.length > 0) {
      return FileKeyPO.fromJson(list[0]);
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
  }
}
