// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileKey _$FileKeyFromJson(Map<String, dynamic> json) {
  return FileKey(
    json['filename'] as String,
    (json['tags'] as List)?.map((e) => e as String)?.toSet(),
    json['star'] as int,
    json['preOpenTime'] == null
        ? null
        : DateTime.parse(json['preOpenTime'] as String),
    json['preMonthOpenTime'] == null
        ? null
        : DateTime.parse(json['preMonthOpenTime'] as String),
    json['preSeasonOpenTime'] == null
        ? null
        : DateTime.parse(json['preSeasonOpenTime'] as String),
    json['monthScore'] as int,
    json['seasonScore'] as int,
    json['yearScore'] as int,
  );
}

Map<String, dynamic> _$FileKeyToJson(FileKey instance) => <String, dynamic>{
      'filename': instance.filename,
      'tags': instance.tags?.toList(),
      'star': instance.star,
      'preOpenTime': instance.preOpenTime?.toIso8601String(),
      'preMonthOpenTime': instance.preMonthOpenTime?.toIso8601String(),
      'preSeasonOpenTime': instance.preSeasonOpenTime?.toIso8601String(),
      'monthScore': instance.monthScore,
      'seasonScore': instance.seasonScore,
      'yearScore': instance.yearScore,
    };

FileInfo _$FileInfoFromJson(Map<String, dynamic> json) {
  return FileInfo(
    json['filename'] as String,
  )
    ..smbId = json['smbId'] as String
    ..absPath = json['absPath'] as String
    ..isDirectory = json['isDirectory'] as bool
    ..isCompressFile = json['isCompressFile'] as bool
    ..fileKey = json['fileKey'] == null
        ? null
        : FileKey.fromJson(json['fileKey'] as Map<String, dynamic>)
    ..star = json['star'] as int
    ..readLenght = json['readLenght'] as int
    ..length = json['length'] as int
    ..size = json['size'] as int;
}

Map<String, dynamic> _$FileInfoToJson(FileInfo instance) => <String, dynamic>{
      'smbId': instance.smbId,
      'absPath': instance.absPath,
      'filename': instance.filename,
      'isDirectory': instance.isDirectory,
      'isCompressFile': instance.isCompressFile,
      'fileKey': instance.fileKey,
      'star': instance.star,
      'readLenght': instance.readLenght,
      'length': instance.length,
      'size': instance.size,
    };