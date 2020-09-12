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
    (json['clickTimes'] as List)
        ?.map((e) => e == null ? null : DateTime.parse(e as String))
        ?.toList(),
    (json['readTimes'] as List)?.map((e) => e as int)?.toList(),
  );
}

Map<String, dynamic> _$FileKeyToJson(FileKey instance) => <String, dynamic>{
      'filename': instance.filename,
      'tags': instance.tags,
      'star': instance.star,
      'clickTimes':
          instance.clickTimes?.map((e) => e?.toIso8601String())?.toList(),
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

Map<String, dynamic> _$ZipFileContentToJson(ZipFileContent instance) =>
    <String, dynamic>{
      'absFilename': instance.absFilename,
      'zipFilename': instance.zipFilename,
      'index': instance.index,
      'length': instance.length,
      'content': instance.content,
    };

SmbHalfResult _$SmbHalfResultFromJson(Map<String, dynamic> json) {
  return SmbHalfResult(
    json['msg'] as String,
    (json['result'] as Map<String, dynamic>)?.map(
      (k, e) => MapEntry(
          int.parse(k),
          e == null
              ? null
              : ZipFileContent.fromJson(e as Map<String, dynamic>)),
    ),
  );
}

Map<String, dynamic> _$SmbHalfResultToJson(SmbHalfResult instance) =>
    <String, dynamic>{
      'msg': instance.msg,
      'result': instance.result?.map((k, e) => MapEntry(k.toString(), e)),
    };

