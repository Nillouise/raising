import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:raising/common/JsonConverter.dart';

part 'ExploreCO.g.dart';

@JsonSerializable()
@CustomDateTimeConverter()
@MapIntUint8listConverter()
class ExploreCO {
  /**
   * 注意，absPath实测在webdav中，会被url编码（但filename却不会），所以这里涉及absPath的需要处理好
   * 一般来说不需要注意，但搜索时，可能需要先转换好url encode才行，又或者需要显示absPath，就需要被urlDecode。
   */
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
