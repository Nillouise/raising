import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:raising/channel/Smb.dart';

Future<Uint8List> compressImage(Uint8List list) async {
  var result = await FlutterImageCompress.compressWithList(
    list,
    minHeight: 2560,
    minWidth: 1440,
    quality: 70,
  );
  return Uint8List.fromList(result);
}

void putImageToCache(String absFilename, int index, Uint8List fileBytes,
    {bool needFileDetailInfo: false, Smb smb, bool needCompress = true}) async {
  if (smb == null) {
    smb = Smb.getCurrentSmb();
  }

  await DefaultCacheManager().putFile(
      [smb.id, absFilename, index, needCompress].join("@"),
      await compressImage(fileBytes));
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
