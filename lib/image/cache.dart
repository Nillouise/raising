import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:raising/channel/Smb.dart';

void putImageToCache(String absFilename, int index, Uint8List fileBytes,
    {bool needFileDetailInfo: false, Smb smb}) async {
  if (smb == null) {
    smb = Smb.getCurrentSmb();
  }
  await DefaultCacheManager()
      .putFile([smb.id, absFilename, index].join("@"), fileBytes);
}

Future<Uint8List> getImageFromCache(String absFilename, int index,
    {bool needFileDetailInfo: false, Smb smb}) async {
  if (smb == null) {
    smb = Smb.getCurrentSmb();
  }
  FileInfo fileInfo = await DefaultCacheManager()
      .getFileFromCache([smb.id, absFilename, index].join("@"));
  if (fileInfo == null) {
    return null;
  } else {
    return await fileInfo.file.readAsBytes();
  }
}
