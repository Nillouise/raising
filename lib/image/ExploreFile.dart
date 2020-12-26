import 'dart:typed_data';

import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/client/WebDavClient.dart';
import 'package:raising/client/file.dart' as webdavfile;

import 'ExploreCO.dart';
import 'ExtractCO.dart';
import 'WholeFileContentCO.dart';
import 'dart:io';

/**
 * 先前我没有提供更原子的api（即把缓存，压缩，获取文件的api分离），而是直接编写高级api，导致现在改也麻烦。
 * 应该先用原子的api做多几个功能，等出现问题再优化。
 */
abstract class ExploreFile {
  Future<List<ExploreCO>> queryFiles(String path);

  Stream<List<ExploreCO>> bfsFiles(String path);

  Stream<List<ExploreCO>> searchFiles(String path, String searchKeyword);

  /// Throw SmbException if get file error
  Future<ExtractCO> loadFileFromZip(String path, int index);

  /// 太大的文件应当上层判断不要load，因为是load到内存里
   Future<WholeFileContentCO> loadWholeFile(String path);
}

class WebdavExploreFile implements ExploreFile {
  WebDavClient client = WebDavClient("http://192.168.1.111:4697", "", "", "");

  @override
  Stream<List<ExploreCO>> bfsFiles(String path) {
    // TODO: implement loadFileFromZip
    throw UnimplementedError();
  }

  @override
  Future<ExtractCO> loadFileFromZip(String path, int index, {int fileSize: 0}) async {
    final Map<dynamic, dynamic> result = await SmbChannel.methodChannel.invokeMethod("webdavExtract", {"recallId": path, "fileSize": fileSize, "index": index});
    try {
      ExtractCO extractCO = ExtractCO.fromJson(Map<String, dynamic>.from(result));
      if (extractCO.msg == "OK") {
        return extractCO;
      } else {
        return null;
      }
    } catch (e) {
      logger.d("nativeCaller {}", e);
      return null;
    }
  }

  @override
  Future<WholeFileContentCO> loadWholeFile(String path) async {
    var content = await client.downloadToBinary(path);
    return WholeFileContentCO()..content = content.first as Uint8List;
  }

  List<ExploreCO> convertExploreCO(List<webdavfile.FileInfo> lst) {
    List<ExploreCO> res = List<ExploreCO>();
    lst.forEach((e) {
      res.add(ExploreCO()
        ..absPath = e.path
        ..size = int.parse(e.size==""?"0":e.size)
        ..updateTime = HttpDate.parse(e.modificationTime)
        ..createTime = e.creationTime
        ..filename = e.name
        ..isDirectory = e.isDirectory);
    });
    return res;
  }

  @override
  Future<List<ExploreCO>> queryFiles(String path) async {
    List<webdavfile.FileInfo> rec = await client.ls(path: path, depth: 1);
    return convertExploreCO(rec);
  }

  @override
  Stream<List<ExploreCO>> searchFiles(String path, String searchKeyword) {
    // TODO: implement searchFiles
    throw UnimplementedError();
  }
}
