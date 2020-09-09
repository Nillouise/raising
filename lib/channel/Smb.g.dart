// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Smb.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Smb _$SmbFromJson(Map<String, dynamic> json) {
  return Smb(
    hostname: json['hostname'] as String,
    shareName: json['shareName'] as String,
    domain: json['domain'] as String,
    username: json['username'] as String,
    password: json['password'] as String,
    path: json['path'] as String,
    searchPattern: json['searchPattern'] as String,
  )
    ..id = json['id'] as String
    ..realNickName = json['realNickName'] as String
    ..nickName = json['nickName'] as String;
}

Map<String, dynamic> _$SmbToJson(Smb instance) => <String, dynamic>{
      'id': instance.id,
      'realNickName': instance.realNickName,
      'hostname': instance.hostname,
      'shareName': instance.shareName,
      'domain': instance.domain,
      'username': instance.username,
      'password': instance.password,
      'path': instance.path,
      'searchPattern': instance.searchPattern,
      'nickName': instance.nickName,
    };
