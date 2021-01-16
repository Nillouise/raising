// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ExtractCO.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExtractCO _$ExtractCOFromJson(Map json) {
  return ExtractCO()
    ..msg = json['msg'] as String
    ..error = json['error'] as String
    ..absPath = json['absPath'] as String
    ..filename = json['filename'] as String
    ..size = json['size'] as int
    ..fileNum = json['fileNum'] as int
    ..isDirectory = json['isDirectory'] as bool
    ..isCompressFile = json['isCompressFile'] as bool
    ..createTime =
        const CustomDateTimeConverter().fromJson(json['createTime'] as int)
    ..updateTime =
        const CustomDateTimeConverter().fromJson(json['updateTime'] as int)
    ..compressFormat = json['compressFormat'] as String
    ..indexPath = (json['indexPath'] as Map)?.map(
      (k, e) => MapEntry(int.parse(k as String), e as String),
    )
    ..indexContent = const MapIntUint8listConverter()
        .fromJson(json['indexContent'] as Map<int, Uint8List>);
}

Map<String, dynamic> _$ExtractCOToJson(ExtractCO instance) => <String, dynamic>{
      'msg': instance.msg,
      'error': instance.error,
      'absPath': instance.absPath,
      'filename': instance.filename,
      'size': instance.size,
      'fileNum': instance.fileNum,
      'isDirectory': instance.isDirectory,
      'isCompressFile': instance.isCompressFile,
      'createTime': const CustomDateTimeConverter().toJson(instance.createTime),
      'updateTime': const CustomDateTimeConverter().toJson(instance.updateTime),
      'compressFormat': instance.compressFormat,
      'indexPath': instance.indexPath?.map((k, e) => MapEntry(k.toString(), e)),
      'indexContent':
          const MapIntUint8listConverter().toJson(instance.indexContent),
    };
