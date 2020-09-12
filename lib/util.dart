import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/SmbVO.dart';
import 'package:raising/exception/SmbException.dart';

import 'constant/Constant.dart';
import 'image/cache.dart';

var logger = Logger();

class Utils {
  static bool invalidFilename(String x) {
    return x.endsWith("\$");
  }

  static Map filterEmptyFied(Map x) {}

  static String getAbsPath(String path, String filename) {}

  static bool isCompressFile(String absPath) {
    return Constants.COMPRESS_FILE.contains(p.extension(absPath));
  }

  static bool isImageFile(String absPath) {
    return Constants.IMAGE_FILE.contains(p.extension(absPath));
  }

  static bool isCompressOrImageFile(String absPath) {
    return Constants.COMPRESS_AND_IMAGE_FILE.contains(p.extension(absPath));
  }


  /// Throw SmbException if get file error
  static Future<FileContentCO> getWholeFile(SmbVO smbVO, {bool forceFromSource = false}) async {
    CacheVO<FileContentCO> f = await loadFromCache<FileContentCO>("WholeFile@" + smbVO.id + "@" + smbVO.absPath, () {
      return SmbChannel.loadWholeFile(smbVO);
    }, forceFromSource: forceFromSource);
    if (f.code == CacheResult.ok) {
      if (f.source == CacheSource.originSource) {
        return f.metaObj;
      } else {
        return FileContentCO()
          ..absFilename = smbVO.absPath
          ..content = f.file;
      }
    }else{
      throw SmbException("getWholeFile error");
    }
  }

  static Future<FileContentCO> getFileFromZip(int index, SmbVO smbVO, {bool forceFromSource = false}) async {
    CacheVO<FileContentCO> f = await loadFromCache<FileContentCO>("fileFromZip@" + smbVO.id + "@" + smbVO.absPath + "@$index", () {
      return SmbChannel.loadFileFromZip(index, smbVO);
    }, forceFromSource: forceFromSource);
    if (f.code == CacheResult.ok) {
      if (f.source == CacheSource.originSource) {
        return f.metaObj;
      } else {
        return FileContentCO()
          ..absFilename = smbVO.absPath
          ..content = f.file;
      }
    }else{
      throw SmbException("getFileFromZip error");
    }
  }

  static String joinPath(String a, String b) {
    a = a??"";
    if (p.isAbsolute(b)) {
      var split = p.split(b);
      split[0] = a;
      return p.joinAll(split);
    } else {
      return p.join(a, b);
    }
  }
}
