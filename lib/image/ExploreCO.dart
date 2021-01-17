import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:raising/common/JsonConverter.dart';

part 'ExploreCO.g.dart';

@JsonSerializable()
@CustomDateTimeConverter()
@MapIntUint8listConverter()
class ExploreCO {
  String absPath; //总是包括filename(如果是文件夹，则包括到文件夹名），只有当没有absPath时，再去查filename字段
  String filename;
  int size;
  int fileNum; //如果是压缩文件里面有多少文件，如果是目录，里面有多少文件
  bool isDirectory = false;
  DateTime createTime;
  DateTime updateTime;

  factory ExploreCO.fromJson(Map<String, dynamic> json) => _$ExploreCOFromJson(json);

  Map<String, dynamic> toJson() => _$ExploreCOToJson(this);

  ExploreCO();
}
