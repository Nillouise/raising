import 'dart:typed_data';

import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/client/client.dart';
import 'package:raising/client/file.dart' as webdavfile;

import 'ExploreCO.dart';
import 'ExtractCO.dart';
import 'WholeFileContentCO.dart';

/**
 * ��ǰ��û���ṩ��ԭ�ӵ�api�����ѻ��棬ѹ������ȡ�ļ���api���룩������ֱ�ӱ�д�߼�api���������ڸ�Ҳ�鷳��
 * Ӧ������ԭ�ӵ�api���༸�����ܣ��ȳ����������Ż���
 */
abstract class ExploreFile {
  Future<List<ExploreCO>> queryFiles(String path);

  Stream<List<ExploreCO>> bfsFiles(String path);

  Stream<List<ExploreCO>> searchFiles(String path, String searchKeyword);

  /// Throw SmbException if get file error
  Future<ExtractCO> loadFileFromZip(String path, int index);

  /// ̫����ļ�Ӧ���ϲ��жϲ�Ҫload����Ϊ��load���ڴ���
  Future<WholeFileContentCO> loadWholeFile(String path);
}

class WebdavExploreFile implements ExploreFile {
  WebDavClient client = WebDavClient("http://109.131.14.238:37536/", "", "", "");

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
        ..size = int.parse(e.size)
        ..updateTime = DateTime.parse(e.modificationTime)
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
