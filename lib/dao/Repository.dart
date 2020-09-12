import 'dart:async';
import 'dart:ffi';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/exception/DbException.dart';
import 'package:sqflite/sqflite.dart';

class Repository {
  static Database _cache_db;

  static Database _db;

  static void init() async {
    _db = await openDatabase((await getApplicationDocumentsDirectory()).path + "/cur2.db", version: 1, onCreate: (Database db, int version) async {
      await db.execute("CREATE TABLE smb_manage (id TEXT PRIMARY KEY, _nickName TEXT, hostname TEXT,domain TEXT,username TEXT,password TEXT)");

      await db.execute("CREATE TABLE file_key (filename TEXT PRIMARY KEY, star INTEGER)");
      await db.execute("CREATE TABLE file_key_clicks (id INTEGER PRIMARY KEY, filename TEXT, clickTime INTEGER, readTime INTEGER)");
      await db.execute("CREATE INDEX file_key_clicks_index ON file_key_clicks(filename)");
      await db.execute("CREATE TABLE file_key_tags (id INTEGER PRIMARY KEY, filename TEXT, tag TEXT)");
      await db.execute("CREATE INDEX file_key_tags_index ON file_key_tags(filename)");

      //File info
      await db.execute(
          "CREATE TABLE file_info (id INTEGER PRIMARY KEY,smbId TEXT,smbNickName TEXT,absPath TEXT, filename TEXT, updateTime INTEGER, isDirectory INTEGER, isShare INTEGER, isCompressFile INTEGER, readLenght INTEGER, fileNum INTEGER, size INTEGER)");
      await db.execute("CREATE UNIQUE INDEX file_info_index ON file_info(smbId, absPath)");
    });

    _cache_db = _db;
    print(_db);
  }

  static Future<List<SmbPO>> getAllSmbPO() async {
    List<Map<String, dynamic>> list = await _db.transaction((txn) async {
      return await txn.rawQuery(
        "select * from smb_manage",
      );
    });
    return list.map((e) => SmbPO.fromJson(e)).toList();
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

  static Future<bool> upsertFileInfo(String absPath, String smbId, String smbNickName,
      {DateTime updateTime,
      bool isDirectory,
      bool isCompressFile,
      bool isShare,
      int readLenght,
      int size, //文件大小
      int fileNum}) async {
    Map<String, dynamic> map = {"absPath": absPath, "smbId": smbId, "smbNickName": smbNickName, "filename": p.basename(absPath)};
    if (updateTime != null) {
      map["updateTime"] = updateTime.millisecondsSinceEpoch;
    }
    if (isDirectory != null) {
      map["isDirectory"] = isDirectory;
    }
    if (isCompressFile != null) {
      map["isCompressFile"] = isCompressFile;
    }
    if (isShare != null) {
      map["isShare"] = isShare;
    }
    if (readLenght != null) {
      map["readLenght"] = readLenght;
    }
    if (size != null) {
      map["size"] = size;
    }
    if (fileNum != null) {
      map["fileNum"] = fileNum;
    }

    int res = await _db.transaction((txn) async {
      if ((await txn.query("file_info", where: "smbId=? and absPath=?", whereArgs: [smbId, absPath])).length == 0) {
        return await txn.insert("file_info", map);
      } else {
        return await txn.update("file_info", map, where: "smbId=? and absPath=?", whereArgs: [smbId, absPath]);
      }
    });

    return res > 0;
  }

  static Future<Void> upsertFileKey(
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
  }

  static Future<bool> deleteFileKeyTag(String filename, String tag) {
    //TODO:
  }

  static Future<FileKeyPO> getFileKey(String filename) async {
    List<Map<String, dynamic>> list = await _db.rawQuery('SELECT * FROM file_key');
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
