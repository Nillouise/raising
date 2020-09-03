// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileKey _$FileKeyFromJson(Map<String, dynamic> json) {
  return FileKey(
    json['filename'] as String,
    (json['tags'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(k, e as String),
    ),
    json['star'] as int,
    (json['clickTimes'] as List)?.map((e) => e == null ? null : (DateTime.fromMicrosecondsSinceEpoch(e * 1000)))?.toList(),
    (json['readTimes'] as List)?.map((e) => e as int)?.toList(),
  );
}

Map<String, dynamic> _$FileKeyToJson(FileKey instance) => <String, dynamic>{
      'filename': instance.filename,
      'tags': instance.tags,
      'star': instance.star,
      'clickTimes': instance.clickTimes?.map((e) => e?.toIso8601String())?.toList(),
      'readTimes': instance.readTimes,
    };

ZipFileContent _$ZipFileContentFromJson(Map<String, dynamic> json) {
  return ZipFileContent(
    json['absFilename'] as String,
    json['zipFilename'] as String,
    json['index'] as int,
    json['length'] as int,
    json['content'],
  );
}

Map<String, dynamic> _$ZipFileContentToJson(ZipFileContent instance) => <String, dynamic>{
      'absFilename': instance.absFilename,
      'zipFilename': instance.zipFilename,
      'index': instance.index,
      'length': instance.length,
      'content': instance.content,
    };

SmbHalfResult _$SmbHalfResultFromJson(Map<String, dynamic> json) {
  return SmbHalfResult(
    json['msg'] as String,
    (Map<String, dynamic>.from(json['result']))?.map(
      (k, e) => MapEntry(int.parse(k), e == null ? null : ZipFileContent.fromJson(Map<String, dynamic>.from(e))),
    ),
  );
}

Map<String, dynamic> _$SmbHalfResultToJson(SmbHalfResult instance) => <String, dynamic>{
      'msg': instance.msg,
      'result': instance.result?.map((k, e) => MapEntry(k.toString(), e)),
    };

FileInfo _$FileInfoFromJson(Map<String, dynamic> json) {
  return FileInfo()
    ..smbId = json['smbId'] as String
    ..smbNickName = json['smbNickName'] as String
    ..absPath = json['absPath'] as String
    ..filename = json['filename'] as String
    ..updateTime = json['updateTime'] == null ? null : DateTime.parse(json['updateTime'] as String)
    ..isDirectory = json['isDirectory'] as bool
    ..isCompressFile = json['isCompressFile'] as bool
    ..fileKey = json['fileKey'] == null ? null : FileKey.fromJson(json['fileKey'] as Map<String, dynamic>)
    ..star = json['star'] as int
    ..readLenght = json['readLenght'] as int
    ..length = json['length'] as int
    ..size = json['size'] as int;
}

Map<String, dynamic> _$FileInfoToJson(FileInfo instance) => <String, dynamic>{
      'smbId': instance.smbId,
      'smbNickName': instance.smbNickName,
      'absPath': instance.absPath,
      'filename': instance.filename,
      'updateTime': instance.updateTime?.toIso8601String(),
      'isDirectory': instance.isDirectory,
      'isCompressFile': instance.isCompressFile,
      'fileKey': instance.fileKey,
      'star': instance.star,
      'readLenght': instance.readLenght,
      'length': instance.length,
      'size': instance.size,
    };
