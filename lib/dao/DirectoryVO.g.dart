// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'DirectoryVO.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileInfoPO _$FileInfoPOFromJson(Map json) {
  return FileInfoPO()
    ..fileId = json['fileId'] as String
    ..hostId = json['hostId'] as String
    ..hostNickName = json['hostNickName'] as String
    ..absPath = json['absPath'] as String
    ..filename = json['filename'] as String
    ..updateTime =
        const CustomDateTimeConverter().fromJson(json['updateTime'] as int)
    ..size = json['size'] as int
    ..isDirectory = json['isDirectory'] as bool
    ..isCompressFile = json['isCompressFile'] as bool
    ..isShare = json['isShare'] as bool
    ..readLenght = json['readLenght'] as int
    ..fileNum = json['fileNum'] as int
    ..recentReadTime =
        const CustomDateTimeConverter().fromJson(json['recentReadTime'] as int);
}

Map<String, dynamic> _$FileInfoPOToJson(FileInfoPO instance) =>
    <String, dynamic>{
      'fileId': instance.fileId,
      'hostId': instance.hostId,
      'hostNickName': instance.hostNickName,
      'absPath': instance.absPath,
      'filename': instance.filename,
      'updateTime': const CustomDateTimeConverter().toJson(instance.updateTime),
      'size': instance.size,
      'isDirectory': instance.isDirectory,
      'isCompressFile': instance.isCompressFile,
      'isShare': instance.isShare,
      'readLenght': instance.readLenght,
      'fileNum': instance.fileNum,
      'recentReadTime':
          const CustomDateTimeConverter().toJson(instance.recentReadTime),
    };

FileKeyPO _$FileKeyPOFromJson(Map json) {
  return FileKeyPO(
    fileId: json['fileId'] as String,
    filename: json['filename'] as String,
    star: json['star'] as int,
    score14: (json['score14'] as num)?.toDouble(),
    score60: (json['score60'] as num)?.toDouble(),
    recentReadTime:
        const CustomDateTimeConverter().fromJson(json['recentReadTime'] as int),
  );
}

Map<String, dynamic> _$FileKeyPOToJson(FileKeyPO instance) => <String, dynamic>{
      'fileId': instance.fileId,
      'filename': instance.filename,
      'star': instance.star,
      'score14': instance.score14,
      'score60': instance.score60,
      'recentReadTime':
          const CustomDateTimeConverter().toJson(instance.recentReadTime),
    };
