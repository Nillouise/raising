import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;

import 'channel/Smb.dart';
import 'constant/Constant.dart';
import 'image/cache.dart';
import 'model/file_info.dart';

var logger = Logger();

class Utils {
  static bool invalidFilename(String x) {
    return x.endsWith("\\$");
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

  static Future<SmbHalfResult> getImage(int index, String absPath, bool needFileDetailInfo, String share) async {
    if (needFileDetailInfo) {
      logger.i("getImage needFileDetailInfo load from origin file $share $absPath $index");
      SmbHalfResult smbHalfResult = await Smb.getCurrentSmb().loadImageFromIndex(absPath, index, share, needFileDetailInfo: needFileDetailInfo);
      if (smbHalfResult.msg == "successful") {
        putImageToCache(absPath, index, smbHalfResult.result[index].content);
      }
      return smbHalfResult;
    }
    var cacheImage = await getImageFromCache(absPath, index);
    if (cacheImage == null) {
      logger.i("getImage cache have not $share $absPath $index and load from origin file");
      SmbHalfResult smbHalfResult = await Smb.getCurrentSmb().loadImageFromIndex(absPath, index, share, needFileDetailInfo: needFileDetailInfo);
      if (smbHalfResult.msg == "successful") {
        putImageToCache(absPath, index, smbHalfResult.result[index].content);
      }
      return smbHalfResult;
    } else {
      logger.i("getImage load from cache $share $absPath $index");
      return SmbHalfResult("successful", {index: ZipFileContent.content(cacheImage)});
    }
  }

  static Future<SmbHalfResult> getPreviewFile(int index, String absPath, String share) async {
    var content = await getImageFromCache(absPath, index);
    if (content == null) {
      logger.i("getImage cache have not $share $absPath $index and load from origin file");
      var currentSmb = Smb.getCurrentSmb();
      SmbHalfResult smbHalfResult;
      if (isCompressOrImageFile(absPath)) {
        smbHalfResult = await currentSmb.loadImageFromIndex(absPath, index, share, needFileDetailInfo: true);
      } else if (isImageFile(absPath)) {
        smbHalfResult = await currentSmb.loadImageFile(absPath, share);
      }
      if (smbHalfResult.msg == "successful") {
        putImageToCache(absPath, index, smbHalfResult.result[index].content);
      }
      return smbHalfResult;
    } else {
      logger.i("getPreviewFile load from cache $share $absPath $index");
      return SmbHalfResult("successful", {index: ZipFileContent.content(content)});
    }
  }
}
