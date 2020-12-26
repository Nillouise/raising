// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DirectoryVO.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DirectoryCO _$DirectoryCOFromJson(Map<String, dynamic> json) {
  return DirectoryCO()
    ..filename = json['filename'] as String
    ..updateTime = json['updateTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['updateTime'])
    ..size = json['size'] as int
    ..isDirectory = json['isDirectory'] as bool
    ..isComprssFile = json['isComprssFile'] as bool
    ..isShare = json['isShare'] as bool
    ..fileNum = json['fileNum'] as int;
}

Map<String, dynamic> _$DirectoryCOToJson(DirectoryCO instance) => <String, dynamic>{
      'filename': instance.filename,
      'updateTime': instance.updateTime?.toIso8601String(),
      'size': instance.size,
      'isDirectory': instance.isDirectory,
      'isComprssFile': instance.isComprssFile,
      'isShare': instance.isShare,
      'fileNum': instance.fileNum,
    };

FileInfoPO _$FileInfoPOFromJson(Map<String, dynamic> json) {
  return FileInfoPO()
    ..smbId = json['smbId'] as String
    ..smbNickName = json['smbNickName'] as String
    ..absPath = json['absPath'] as String
    ..filename = json['filename'] as String
    ..updateTime = json['updateTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['updateTime'] as int)
    ..recentReadTime = json['recentReadTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['recentReadTime'] as int)
    ..size = json['size'] as int
    ..isDirectory = json['isDirectory'] as bool
    ..isCompressFile = json['isComprssFile'] as bool
    ..isShare = json['isShare'] as bool
    ..readLenght = json['readLenght'] as int
    ..fileNum = json['fileNum'] as int;
}

Map<String, dynamic> _$FileInfoPOToJson(FileInfoPO instance) => <String, dynamic>{
      'smbId': instance.smbId,
      'smbNickName': instance.smbNickName,
      'absPath': instance.absPath,
      'filename': instance.filename,
      'updateTime': instance.updateTime?.millisecondsSinceEpoch,
      'recentReadTime': instance.recentReadTime?.millisecondsSinceEpoch,
      'size': instance.size,
      'isDirectory': instance.isDirectory,
      'isComprssFile': instance.isCompressFile,
      'isShare': instance.isShare,
      'readLenght': instance.readLenght,
      'fileNum': instance.fileNum,
    };

FileContentCO _$ZipFileContentCOFromJson(Map<String, dynamic> json) {
  return FileContentCO()
    ..absFilename = json['absFilename'] as String
    ..zipAbsFilename = json['zipAbsFilename'] as String
    ..index = json['index'] as int
    ..length = json['length'] as int
    ..wholeFileSize = json['wholeFileSize'] as int
    ..content = json['content'];
}

Map<String, dynamic> _$ZipFileContentCOToJson(FileContentCO instance) => <String, dynamic>{
      'filename': instance.absFilename,
      'zipAbsFilename': instance.zipAbsFilename,
      'index': instance.index,
      'length': instance.length,
      'content': instance.content,
    };

//FileKeyPO _$FileKeyPOFromJson(Map<String, dynamic> json) {
//  return FileKeyPO(
//    json['filename'] as String,
//    (json['tags'] as Map<String, dynamic>)?.map(
//      (k, e) => MapEntry(k, e as String),
//    ),
//    json['star'] as int,
//    (json['clickTimes'] as List)?.map((e) => e == null ? null : DateTime.parse(e as String))?.toList(),
//    (json['readTimes'] as List)?.map((e) => e as int)?.toList(),
//  );
//}
//
//Map<String, dynamic> _$FileKeyPOToJson(FileKeyPO instance) => <String, dynamic>{
//      'filename': instance.filename,
//      'tags': instance.tags,
//      'star': instance.star,
//      'clickTimes': instance.clickTimes?.map((e) => e?.toIso8601String())?.toList(),
//      'readTimes': instance.readTimes,
//    };
