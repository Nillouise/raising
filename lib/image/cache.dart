import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logger/logger.dart';

import 'ExtractCO.dart';
import 'WholeFileContentCO.dart';

//重构代码后需要的新cache还没做出来。

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

class ImageCompress {
  static Future<Uint8List> thumbNailImage(Uint8List image) async {
    var result = await FlutterImageCompress.compressWithList(
      image,
      minHeight: 100,
      minWidth: 100,
      quality: 50,
    );
    return Uint8List.fromList(result);
  }
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

class CacheThumbnail {
  static String _getThumbId(String fileId) {
    return "thumbNail@$fileId";
  }

  static Future<void> putThumbnail(Uint8List thumbnail, String fileId) async {
    await DefaultCacheManager().putFile(_getThumbId(fileId), thumbnail);
  }

  static Future<Uint8List> getThumbnail(String fileId) async {
    FileInfo fileInfo = await DefaultCacheManager().getFileFromCache(_getThumbId(fileId));
    if (fileInfo == null) {
      return null;
    }
    return await fileInfo.file.readAsBytes();
  }
}

//TODO: 这里把cahce层的功能做少，不知道是不是个好主意，反正也很难决定cache什么（只有图片？文件信息不cache？）。
class CacheImage {
  void putImage(Uint8List thumbnail, String fileId, String zipId) {}

  Uint8List getImage(String fileId, String zipId) {}
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

String getWholeFileCacheKey(String exploreFileId, String absPath) {
  String res = "img$exploreFileId#$absPath";
  return res;
}

String getExtractCacheKey(String exploreFileId, String absPath, int index) {
  String res = "zip$exploreFileId#$absPath#index";
  return res;
}

Future<WholeFileContentCO> getWholeFileCache(String exploreFileId, String absPath) async {
  var wholeFileCacheKey = getWholeFileCacheKey(exploreFileId, absPath);
  FileInfo fileInfo = await DefaultCacheManager().getFileFromCache(wholeFileCacheKey);
  if (fileInfo == null) {
    //TODO：删除数据库对应的数据
    return null;
  }
  Uint8List uint8list = await fileInfo.file.readAsBytes();
}

Future<ExtractCO> getExtractFileCO(String exploreFileId, String absPath, int index) async {
  var extractCacheKey = getExtractCacheKey(exploreFileId, absPath, index);
  FileInfo fileInfo = await DefaultCacheManager().getFileFromCache(extractCacheKey);
  if (fileInfo == null) {
    //TODO：删除数据库对应的数据
    return null;
  }
  Uint8List uint8list = await fileInfo.file.readAsBytes();
}

//TODO：还需要做一个脏缓存的检查，比如监控ExploreFile的切换。
