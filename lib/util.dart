import 'package:path/path.dart' as p;

import 'channel/Smb.dart';
import 'constant/Constant.dart';
import 'image/cache.dart';
import 'model/file_info.dart';

class Utils {
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

  static Future<SmbHalfResult> getImage(
      int index, String absPath, bool needFileDetailInfo) async {
    if (needFileDetailInfo || await getImageFromCache(absPath, index) == null) {
      SmbHalfResult smbHalfResult = await Smb.getCurrentSmb()
          .loadImageFromIndex(absPath, index,
              needFileDetailInfo: needFileDetailInfo);
      if (smbHalfResult.msg == "successful") {
        putImageToCache(absPath, index, smbHalfResult.result[index].content);
      }
      return smbHalfResult;
    } else {
      return SmbHalfResult("successful", {
        index: ZipFileContent.content(await getImageFromCache(absPath, index))
      });
    }
  }

  static Future<SmbHalfResult> getPreviewFile(int index, String absPath) async {
    var content = await getImageFromCache(absPath, index);
    if (content == null) {
      var currentSmb = Smb.getCurrentSmb();
      SmbHalfResult smbHalfResult;
      if (Constants.COMPRESS_FILE.contains(p.extension(absPath))) {
        smbHalfResult = await currentSmb.loadImageFromIndex(absPath, index,
            needFileDetailInfo: true);
      } else if (Constants.IMAGE_FILE.contains(p.extension(absPath))) {
        smbHalfResult = await currentSmb.loadImageFile(absPath);
      }
      if (smbHalfResult.msg == "successful") {
        putImageToCache(absPath, index, smbHalfResult.result[index].content);
      }
      return smbHalfResult;
    } else {
      return SmbHalfResult(
          "successful", {index: ZipFileContent.content(content)});
    }
  }
}
