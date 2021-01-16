import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:raising/common/JsonConverter.dart';


part 'ExtractCO.g.dart';

@JsonSerializable()
@CustomDateTimeConverter()
@MapIntUint8listConverter()
class ExtractCO {
  String msg;
  String error;
  String absPath; //总是包括filename(如果是文件夹，则包括到文件夹名），只有当没有absPath时，再去查filename字段
  String filename;
  int size;
  int fileNum; //如果是压缩文件里面有多少文件，如果是目录，里面有多少文件
  bool isDirectory = false;
  bool isCompressFile = false;
  DateTime createTime;
  DateTime updateTime;
  String compressFormat;

  //index 按文件名（包括路径排序，第几个文件，跳过文件夹）的排序序号，从0开始。
  Map<int, String> indexPath; //压缩文件内的绝对路径
  Map<int, Uint8List> indexContent;

  factory ExtractCO.fromJson(Map<String, dynamic> json) => _$ExtractCOFromJson(json);

  Map<String, dynamic> toJson() => _$ExtractCOToJson(this);

  ExtractCO();
}
