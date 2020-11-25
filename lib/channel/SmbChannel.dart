import 'dart:collection';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:lpinyin/lpinyin.dart';
import 'package:path/path.dart' as p;
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/SmbResultCO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/exception/SmbException.dart';

var logger = Logger();

class SmbChannel {
  static const MethodChannel methodChannel = MethodChannel('nil/channel');

  static Future<List<DirectoryCO>> queryFiles(SmbVO smbVO) async {
    try {
      SmbCO smbCO = SmbCO.copyFrom(smbVO);
      await methodChannel.invokeMethod("queryFiles", {"smbCO": smbCO.toMap()});
      Map<dynamic, dynamic> result = await methodChannel.invokeMethod("queryFiles", {"smbCO": smbCO.toMap()});
      SmbResultCO smbResult = SmbResultCO.fromJson(Map<String, dynamic>.from(result));
      if (smbResult.msg == SmbResultCO.successful) {
        var list2 = (List<Map<dynamic, dynamic>>.from(smbResult.result));
        List<DirectoryCO> list = list2.map((element) => DirectoryCO.fromJson(Map<String, dynamic>.from(element))).toList();
        return list
          ..removeWhere((element) => ['..', '.', 'IPC\$'].contains(element.filename))
          ..sort((a, b) {
            if (b.updateTime == null || a.updateTime == null) {
              return b.filename.compareTo(a.filename);
            } else {
              return b.updateTime.compareTo(a.updateTime);
            }
          });
      } else {
        throw SmbException(smbResult.msg);
      }
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }

  static Stream<List<DirectoryCO>> bfsFiles(SmbVO smbVO) async* {
    Queue<SmbVO> q = Queue<SmbVO>();
    q.add(smbVO.copy());
    while (q.isNotEmpty) {
      SmbVO c = q.removeFirst();
      print("current queue" + q.length.toString());
      List<DirectoryCO> queryFiles = await SmbChannel.queryFiles(c);
//      yield* SmbChannel.queryFiles(c);
      for (var i in queryFiles) {
        if (i.isDirectory) {
          var copy = c.copy();
          copy.absPath = p.join(copy.absPath ?? "", i.filename);
          q.add(copy);
        }
      }
      yield queryFiles;
    }
  }

  static Stream<List<DirectoryCO>> searchFiles(SmbVO smbVO, String searchKeyword) async* {
    String traditionalKeyword = ChineseHelper.convertToTraditionalChinese(searchKeyword);
    Queue<SmbVO> q = Queue<SmbVO>();
    q.add(smbVO.copy());
    while (q.isNotEmpty) {
      SmbVO c = q.removeFirst();
      print("current queue" + q.length.toString());
      List<DirectoryCO> queryFiles = await SmbChannel.queryFiles(c);
      for (var i in queryFiles) {
        if (i.isDirectory) {
          var copy = c.copy();
          copy.absPath = p.join(copy.absPath ?? "", i.filename);
          q.add(copy);
        }
      }
      //过滤含有关键字的结果
      yield queryFiles
        ..retainWhere((d) {
          if (d.filename != null) {
            return ChineseHelper.convertToTraditionalChinese(d.filename).contains(traditionalKeyword);
          }
          return false;
        });
    }
  }

  /// Throw SmbException if get file error
  static Future<FileContentCO> loadFileFromZip(int index, SmbVO smbVO, {bool needFileDetailInfo = false}) async {
    try {
      SmbCO smbCO = SmbCO.copyFrom(smbVO);
      final Map<dynamic, dynamic> result = await methodChannel.invokeMethod('loadFileFromZip', {
        "indexs": [index],
        "needFileDetailInfo": needFileDetailInfo,
        "smbCO": smbCO.toMap()
      });
      SmbResultCO smbResult = SmbResultCO.fromJson(Map<String, dynamic>.from(result));
      if (smbResult.msg == SmbResultCO.successful) {
        Map<int, dynamic> list2 = (Map<int, dynamic>.from(smbResult.result));
        return FileContentCO.fromJson(Map<String, dynamic>.from(list2[index]));
      } else {
        throw SmbException(smbResult.msg);
      }
    } catch (e) {
      logger.e("loadFileFromZip {}", e);
      throw e;
    }
  }

  /// Throw SmbException if get file error
  static Future<FileContentCO> loadWholeFile(SmbVO smbVO) async {
    try {
      SmbCO smbCO = SmbCO.copyFrom(smbVO);
      final Map<dynamic, dynamic> loadImageFromIndex = await methodChannel.invokeMethod('loadWholeFile', {"smbCO": smbCO.toMap()});
      SmbResultCO res = SmbResultCO.fromJson(new Map<String, dynamic>.from(loadImageFromIndex));
      if (res.msg == SmbResultCO.successful) {
        var list2 = (Map<int, dynamic>.from(res.result));
        var map = Map<String, dynamic>.from(list2[0]);
        return FileContentCO.fromJson(map);
      } else {
        throw SmbException(res.msg);
      }
    } catch (e) {
      logger.e("loadWholeFile {}", e);
      throw e;
    }
  }
}
