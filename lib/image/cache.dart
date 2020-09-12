import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/SmbResultCO.dart';

enum CacheResult {
  ok,
  failed,
}

enum CacheSource { cache, originSource, failed }

class CacheVO<T> {
  CacheResult code;
  CacheSource source;
  Uint8List file;
  T metaObj;

  CacheVO.c(this.code, this.source, this.file, this.metaObj);


}

Future<Uint8List> compressImage(Uint8List list) async {
  var result = await FlutterImageCompress.compressWithList(
    list,
    minHeight: 2560,
    minWidth: 1440,
    quality: 70,
  );
  return Uint8List.fromList(result);
}

Future<Uint8List> getImageFromCache(String absFilename, int index,
    {bool needFileDetailInfo: false, Smb smb, bool needCompress = true}) async {
  if (smb == null) {
    smb = Smb.getCurrentSmb();
  }
  FileInfo fileInfo = await DefaultCacheManager()
      .getFileFromCache([smb.id, absFilename, index, needCompress].join("@"));
  if (fileInfo == null) {
    return null;
  } else {
    return await fileInfo.file.readAsBytes();
  }
}

abstract class CacheContent {
  Uint8List getCacheFile();
}

enum loadFromCacheEnum { low, high }


///use exception to show failed get if getObject throw exception
Future<CacheVO<T>> loadFromCache<T>(String key, Function() getObject,
    {loadFromCacheEnum cacheLevel = loadFromCacheEnum.low,
      bool forceFromSource = false,
      Function(Uint8List) compress = compressImage}) async {
  FileInfo fileInfo = await DefaultCacheManager().getFileFromCache(key);
  if (fileInfo == null || forceFromSource == true) {
    CacheContent r = getObject();
    await DefaultCacheManager().putFile(key,
        compress == null ? r.getCacheFile() : await compress(r.getCacheFile()));
    return CacheVO.c(
        CacheResult.ok, CacheSource.originSource, r.getCacheFile(), r as T);
  } else {
    return CacheVO.c(CacheResult.ok, CacheSource.originSource,
        await fileInfo.file.readAsBytes(), null);
  }
}
