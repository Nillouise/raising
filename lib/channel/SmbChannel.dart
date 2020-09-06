import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/model/file_info.dart';

import 'package:path/path.dart' as p;
import '../util.dart';

var logger = Logger();

class SmbChannel {
  static const MethodChannel methodChannel = MethodChannel('nil/SmbChannel');

  static Future<List<String>> listShares(SmbPO smbPO) async {
    try {
      List<dynamic> list = await methodChannel.invokeMethod('listShares');
      return List<String>.from(list)
        ..removeWhere((element) => Utils.invalidFilename(element));
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }

  static Future<List<FileInfo>> queryFiles(SmbPO smbPO) async {
    try {
      SmbCO smbCO = SmbCO(smbPO);

      smbPO.wholePath = smb
      final String result =
          await methodChannel.invokeMethod("queryFiles", {"SmbPO": smbPO});
      List decode = json.decode(result);
      List<FileInfo> list =
          decode.map((element) => FileInfo.fromJson(element)).toList();
      return list
        ..removeWhere(
            (element) => element.filename == '..' || element.filename == '.')
        ..map((x) {
          x.absPath = p.join(path, x.filename);
          return x;
        }).toList()
        ..sort((a, b) {
          if (b.updateTime == null || a.updateTime == null) {
            return b.filename.compareTo(a.filename);
          } else {
            return b.updateTime.compareTo(a.updateTime);
          }
        });
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }
}
