// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'HostModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HostPO _$HostPOFromJson(Map json) {
  return HostPO()
    ..id = json['id'] as String
    ..nickName = json['nickName'] as String
    ..hostname = json['hostname'] as String
    ..domain = json['domain'] as String
    ..username = json['username'] as String
    ..password = json['password'] as String
    ..type = json['type'] as String;
}

Map<String, dynamic> _$HostPOToJson(HostPO instance) => <String, dynamic>{
      'id': instance.id,
      'nickName': instance.nickName,
      'hostname': instance.hostname,
      'domain': instance.domain,
      'username': instance.username,
      'password': instance.password,
      'type': instance.type,
    };
