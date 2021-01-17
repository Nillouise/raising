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

  /**
   * 在webdav中，这个字段会是uri编码的，因为解码再编码，无法处理（号，所以需要这样做，
   * 之后webdav 数据库搜索（保存了webdav 编码后的absPath），需要处理这种情况
   * 为什么要这样处理？因为webdav的行为看起来很难评估，所以这部分的逻辑真不应该乱搞。
   * 如果存两个absPath 跟orignalAbsPath，也难解决这个问题，因为还是无法解决存到数据库的absPath应该是哪个的问题。
   *
   * 说到底，我当初考虑absPath的时候，就没考虑处理这种要转码的情况的语义（也不知道absPath的相关功能）
   * 目前定义为host相关的唯一原生标识即可，需要转成别的形式的话到时再处理，这样比较好，先用比较原始的语义处理。
   */
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
