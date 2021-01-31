import 'dart:io';
import 'dart:typed_data';

import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/client/WebDavClient.dart';
import 'package:raising/client/file.dart' as webdavfile;
import 'package:raising/model/HostModel.dart';

import 'ExploreCO.dart';
import 'ExtractCO.dart';
import 'WholeFileContentCO.dart';

import 'package:path/path.dart' as p;

/**
 * 先前我没有提供更原子的api（即把缓存，压缩，获取文件的api分离），而是直接编写高级api，导致现在改也麻烦。
 * 应该先用原子的api做多几个功能，等出现问题再优化。
 */
abstract class ExploreFile {
  HostPO getHost();

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

  factory ExploreFile.fromHost(HostPO hostPO) {
    if (hostPO.type == HostPO.hostTypeSamba) {
      return SmbExploreFile(hostPO);
    } else if (hostPO.type == HostPO.hostTypeWebdav) {
      return WebdavExploreFile(hostPO);
    } else {
      throw Exception("hostType error $hostPO}");
    }
  }
}

class SmbExploreFile implements ExploreFile {
  final HostPO hostPO;

  SmbExploreFile(this.hostPO);

  @override
  Stream<List<ExploreCO>> bfsFiles(String path) {
    // TODO: implement bfsFiles
    throw UnimplementedError();
  }

  @override
  Future<ExtractCO> getFileNums(String absPath, {int fileSize}) {
    // TODO: implement getFileNums
    throw UnimplementedError();
  }

  @override
  HostPO getHost() {
    // TODO: implement getHost
    throw UnimplementedError();
  }

  @override
  Future<ExtractCO> loadFileFromZip(String absPath, int index, {int fileSize}) async {
    var arguments = {
      "hostPO": hostPO.toJson(),
      "absPath": absPath,
      "index": index
    };
    final Map<dynamic, dynamic> result =
        await SmbChannel.methodChannel.invokeMethod("smbExtract", arguments);
    var map = Map<String, dynamic>.from(result);
    map["indexPath"] = (Map<int, String>.from(map["indexPath"]))
        ?.map((k, e) => MapEntry((k).toString(), e as String));
    map["indexContent"] = (Map<int, Uint8List>.from(map["indexContent"]))
        ?.map((k, e) => MapEntry(k as int, e as Uint8List));

    ExtractCO extractCO = ExtractCO.fromJson(map);
    if (extractCO.msg == "OK") {
      return extractCO;
    } else {
      return null;
    }
  }

  @override
  Future<WholeFileContentCO> loadWholeFile(String path) {
    // TODO: implement loadWholeFile
    throw UnimplementedError();
  }

  @override
  Future<List<ExploreCO>> queryFiles(String path) async {
    Map arguments = {"hostPO": hostPO.toJson(), "absPath": path};

    try {
      List<dynamic> result = await SmbChannel.methodChannel
          .invokeMethod("smbQueryFiles", arguments);
      return result
          .map((e) => ExploreCO.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    }
  }

  @override
  Future<List<int>> randomRange(String absPath, int begin, int end) {
    // TODO: implement randomRange
    throw UnimplementedError();
  }

  @override
  Stream<List<ExploreCO>> searchFiles(String path, String searchKeyword) {
    // TODO: implement searchFiles
    throw UnimplementedError();
  }
}

class WebdavExploreFile implements ExploreFile {
//  WebDavClient client = WebDavClient("http://109.131.14.238:57203/", "", "", "");
  WebDavClient client;
  Map<String, int> fileSizeCache = Map<String, int>();

  HostPO hostPO;

  WebdavExploreFile(this.hostPO) {
    //TODO:还需要完善
    client =
        WebDavClient(hostPO.hostname, hostPO.username, hostPO.password, "");
  }

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
  Future<ExtractCO> loadFileFromZip(String absPath, int index,
      {int fileSize}) async {
//    final Map<dynamic, dynamic> result = await SmbChannel.methodChannel.invokeMethod("webdavExtract", {"recallId": path, "fileSize": fileSize, "index": index});
    int curFileSize = getFileSizeCache(absPath, fileSize);
    var arguments = {
      "absPathLink": client.baseUrl + absPath,
      "username": client.username,
      "password": client.password,
      "fileSize": curFileSize,
      "index": index
    };
    final Map<dynamic, dynamic> result =
        await SmbChannel.methodChannel.invokeMethod("webdavExtract", arguments);
    var map = Map<String, dynamic>.from(result);
    map["indexPath"] = (Map<int, String>.from(map["indexPath"]))
        ?.map((k, e) => MapEntry((k).toString(), e as String));
    map["indexContent"] = (Map<int, Uint8List>.from(map["indexContent"]))
        ?.map((k, e) => MapEntry(k as int, e as Uint8List));

    ExtractCO extractCO = ExtractCO.fromJson(map);
    if (extractCO.msg == "OK") {
      return extractCO;
    } else {
      return null;
    }
  }

  @override
  Future<WholeFileContentCO> loadWholeFile(String absPath) async {
    var content = await client.downloadToBinary(absPath);
    return WholeFileContentCO()
      ..content = Uint8List.fromList(await content.first);
  }

  List<ExploreCO> convertExploreCO(List<webdavfile.FileInfo> lst) {
    List<ExploreCO> res = List<ExploreCO>();

    lst.forEach((e) {
      res.add(ExploreCO()
        ..absPath =
            e.path //注意这里是个url编码的，而且还不能解码，因为解码再编码就跟原来的不一样，导致请求不了webdav服务器
        ..size = int.parse(e.size == "" ? "0" : e.size)
        ..updateTime = HttpDate.parse(e.modificationTime)
        ..createTime = e.creationTime
        ..filename = e.name
        ..isDirectory = e.isDirectory);
    });
    return res;
  }

  List<ExploreCO> filterUselessWebdavFile(List<ExploreCO> lst) {
    return lst.sublist(1);
    // return lst.where((i)=>i.absPath != "/").toList();
  }

  @override
  Future<List<ExploreCO>> queryFiles(String path) async {
    List<webdavfile.FileInfo> rec = await client.ls(path: path, depth: 1);
    List<ExploreCO> cos = convertExploreCO(rec);
    cos.forEach((element) {
      fileSizeCache[element.absPath] = element.size;
    });
    return filterUselessWebdavFile(cos);
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

  @override
  HostPO getHost() {
    return hostPO;
  }
}
