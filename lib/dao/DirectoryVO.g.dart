// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DirectoryVO.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DirectoryCO _$DirectoryCOFromJson(Map<String, dynamic> json) {
  return DirectoryCO()
    ..filename = json['filename'] as String
    ..updateTime = json['updateTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['updateTime'] as int)
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
