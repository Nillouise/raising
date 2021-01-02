import 'dart:io';
import 'dart:typed_data';

import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/client/WebDavClient.dart';
import 'package:raising/client/file.dart' as webdavfile;

import 'ExploreCO.dart';
import 'ExtractCO.dart';
import 'WholeFileContentCO.dart';

/**
 * 先前我没有提供更原子的api（即把缓存，压缩，获取文件的api分离），而是直接编写高级api，导致现在改也麻烦。
 * 应该先用原子的api做多几个功能，等出现问题再优化。
 */
abstract class ExploreFile {
  Future<List<ExploreCO>> queryFiles(String path);

  Stream<List<ExploreCO>> bfsFiles(String path);

  Stream<List<ExploreCO>> searchFiles(String path, String searchKeyword);

  /// Throw SmbException if get file error
  Future<ExtractCO> loadFileFromZip(String absPath, int index, {int fileSize});

  /// Throw SmbException if get file error
  Future<ExtractCO> getFileNums(String absPath, {int fileSize});

  /// 太大的文件应当上层判断不要load，因为是load到内存里
  Future<WholeFileContentCO> loadWholeFile(String path);

  Future<List<int>> randomRange(String absPath, int begin, int end);
}

class WebdavExploreFile implements ExploreFile {
  WebDavClient client = WebDavClient("http://192.168.1.111:9016", "", "", "");
  Map<String, int> fileSizeCache = Map<String, int>();

  int getFileSizeCache(String absPath, int forceFileSize) {
    if (absPath?.isEmpty ?? true) {
      return forceFileSize ?? 0;
    }
    int curFileSize;
    curFileSize = fileSizeCache[absPath];
    if (absPath.startsWith("/") || absPath.startsWith("\\\\")) {
      curFileSize = curFileSize ?? (fileSizeCache[absPath.substring(1)]);
    } else {
      curFileSize = curFileSize ?? (fileSizeCache["\\\\" + absPath]);
      curFileSize = curFileSize ?? (fileSizeCache["/" + absPath]);
    }
    curFileSize = forceFileSize ?? curFileSize;
    curFileSize = curFileSize ?? 0;
    return curFileSize;
  }

  @override
  Stream<List<ExploreCO>> bfsFiles(String path) {
    // TODO: implement loadFileFromZip
    throw UnimplementedError();
  }

  /**
   * TODO：fileSize这里应当被缓存起来，不然之后可能会有麻烦。
   */
  @override
  Future<ExtractCO> loadFileFromZip(String absPath, int index, {int fileSize}) async {
//    final Map<dynamic, dynamic> result = await SmbChannel.methodChannel.invokeMethod("webdavExtract", {"recallId": path, "fileSize": fileSize, "index": index});
    int curFileSize = getFileSizeCache(absPath, fileSize);
    final Map<dynamic, dynamic> result = await SmbChannel.methodChannel.invokeMethod("webdavExtract", {"recallId": absPath, "fileSize": curFileSize, "index": index});
    ExtractCO extractCO = ExtractCO.fromJson(Map<String, dynamic>.from(result));
    if (extractCO.msg == "OK") {
      return extractCO;
    } else {
      return null;
    }
  }

  @override
  Future<WholeFileContentCO> loadWholeFile(String path) async {
    var content = await client.downloadToBinary(path);
    return WholeFileContentCO()..content = Uint8List.fromList(await content.first);
  }

  List<ExploreCO> convertExploreCO(List<webdavfile.FileInfo> lst) {
    List<ExploreCO> res = List<ExploreCO>();
    lst.forEach((e) {
      res.add(ExploreCO()
        ..absPath = e.path
        ..size = int.parse(e.size == "" ? "0" : e.size)
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
    List<ExploreCO> cos = convertExploreCO(rec);
    cos.forEach((element) {
      fileSizeCache[element.absPath] = element.size;
    });
    return cos;
  }

  @override
  Stream<List<ExploreCO>> searchFiles(String path, String searchKeyword) {
    // TODO: implement searchFiles
    throw UnimplementedError();
  }

  @override
  Future<List<int>> randomRange(String absPath, int begin, int end) async {
    Stream<List<int>> list = await client.getByRange(absPath, begin, end);
//  Stream<List<int>> list = await client.getByRange(methodCall.arguments["url"] as String, methodCall.arguments["begin"] as int, methodCall.arguments["end"] as int);
    List<int> r = await list.first;
    return r;
  }

  @override
  Future<ExtractCO> getFileNums(String absPath, {int fileSize}) {
    return loadFileFromZip(absPath, 0);
  }
}
