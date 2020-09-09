import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
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
      SmbResult smbResult = SmbResult.fromJson(Map<String, dynamic>.from(result));
      if (smbResult.msg == SmbResult.successful) {
        var list2 = (List<Map<dynamic, dynamic>>.from(smbResult.result));
        List<DirectoryCO> list = list2.map((element) => DirectoryCO.fromJson(Map<String, dynamic>.from(element))).toList();
        return list
          ..removeWhere((element) => element.filename == '..' || element.filename == '.')
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
}
