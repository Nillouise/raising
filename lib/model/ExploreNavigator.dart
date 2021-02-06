import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:raising/dao/DirectoryVO.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/image/ExploreCO.dart';
import 'package:raising/image/ExploreFile.dart';
import 'package:raising/image/cache.dart';

var logger = Logger();

/**
 * 本类是用于在浏览目录的时候使用，本类应该控制一切数据的流动，即涉及数据库的
 * 都应该通过本类的接口调用，至于要不要刷新，可以由上层接口决定。
 *
 * notify之后的_files数据不一定是最新的，因为本来就可能不会显示queryFiles里的file，比如说
 * 之后做一个功能，先选中host，再搜索，但这其实根本就不会需要awaitQueryFiles。
 */

class ExploreNavigator extends ChangeNotifier {
  ExploreFile exploreFile;
  String _title;

  String get title => absPath;

  set title(String title) {
    _title = title;
  }

  String absPath;
  List<ExploreCO> _files = List<ExploreCO>();

  List<ExploreCO> get files => _files;

  set files(List<ExploreCO> files) {
    _files = files;
  }

  String getFileId(ExploreCO co) {
    return exploreFile.getHost().id + "@!@" + co.absPath;
  }

  Future<void> putThmnailFile(ExploreCO co, Uint8List thumbNail) async {
    CacheThumbnail.putThumbnail(await ImageCompress.thumbNailImage(thumbNail), getFileId(co));
  }

  ///当一本书被点击后，应该保存在数据库里的数据
  Future<void> saveReadInfo(FileKeyPO keyPO) async {
    await Repository.upsertFileKeyNew(keyPO);
  }

  Future<FileKeyPO> getFileKeyPO(String fileId) async {
    return await Repository.getFileKey(fileId);
  }

  Future<void> saveExploreCO(List<ExploreCO> lst) async {
    //TODO: FIleINFOpo 应该都不需要暴露出去。
    lst?.forEach((e) async {
      FileInfoPO po = FileInfoPO.fromJson(e.toJson());
      po
        ..fileId = getFileId(e)
        ..hostId = exploreFile.getHost().id
        ..hostNickName = exploreFile.getHost().nickName;
      await Repository.upsertFileInfoNew(po);
    });
  }

  void refresh(ExploreFile exploreFile, String absPath) async {
    this.exploreFile = exploreFile;
    this.absPath = absPath;
    notifyListeners();
  }

  void refreshPath(String absPath) {
    this.absPath = absPath;
    notifyListeners();
  }

  Future<ExploreNavigator> awaitQueryFiles() async {
    List<ExploreCO> list = await exploreFile.queryFiles(absPath);
    files = list;
    await saveExploreCO(list);
    return this;
  }

  bool isRoot() {
    return p.rootPrefix(absPath) == absPath && (absPath?.isEmpty ?? true);
    // return false;
  }

  bool isSelectHost() {
    return exploreFile != null;
  }
}
