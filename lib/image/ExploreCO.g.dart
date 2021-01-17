// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ExploreCO.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExploreCO _$ExploreCOFromJson(Map json) {
  return ExploreCO()
    ..absPath = json['absPath'] as String
    ..filename = json['filename'] as String
    ..size = json['size'] as int
    ..fileNum = json['fileNum'] as int
    ..isDirectory = json['isDirectory'] as bool
    ..createTime =
        const CustomDateTimeConverter().fromJson(json['createTime'] as int)
    ..updateTime =
        const CustomDateTimeConverter().fromJson(json['updateTime'] as int);
}

Map<String, dynamic> _$ExploreCOToJson(ExploreCO instance) => <String, dynamic>{
      'absPath': instance.absPath,
      'filename': instance.filename,
      'size': instance.size,
      'fileNum': instance.fileNum,
      'isDirectory': instance.isDirectory,
      'createTime': const CustomDateTimeConverter().toJson(instance.createTime),
      'updateTime': const CustomDateTimeConverter().toJson(instance.updateTime),
    };
