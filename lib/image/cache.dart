import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logger/logger.dart';

var logger = Logger();
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

Future<Uint8List> thumbNailImage(Uint8List image) async {
  var result = await FlutterImageCompress.compressWithList(
    image,
    minHeight: 100,
    minWidth: 100,
    quality: 50,
  );
  return Uint8List.fromList(result);
}

abstract class CacheContent {
  Uint8List getCacheFile();
}

enum loadFromCacheEnum { low, high }

///use exception to show failed get if getObject throw exception
Future<CacheVO<T>> loadFromCache<T>(String key, Function() getObject,
    {loadFromCacheEnum cacheLevel = loadFromCacheEnum.low, bool forceFromSource = false, Function(Uint8List) compress = compressImage}) async {
  FileInfo fileInfo = await DefaultCacheManager().getFileFromCache(key);
  try {
    if (fileInfo == null || forceFromSource == true) {
      CacheContent r = await getObject();
      await DefaultCacheManager().putFile(key, compress == null ? r.getCacheFile() : await compress(r.getCacheFile()));
      return CacheVO.c(CacheResult.ok, CacheSource.originSource, r.getCacheFile(), r as T);
    } else {
      return CacheVO.c(CacheResult.ok, CacheSource.cache, await fileInfo.file.readAsBytes(), null);
    }
  } catch (e) {
    logger.e(e);
  }
}

Future<Uint8List> loadThumbnail(String key) async {
  FileInfo fileInfo = await DefaultCacheManager().getFileFromCache(key);
  if (fileInfo == null) {
    return null;
  }
  return await fileInfo.file.readAsBytes();
}

Future<void> putThumbnail(String key, Uint8List thumbnail) async {
  await DefaultCacheManager().putFile(key, thumbnail);
}
