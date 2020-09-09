import 'package:json_annotation/json_annotation.dart';

part 'DirectoryVO.g.dart';

@JsonSerializable()
class DirectoryCO {
  String filename;
  DateTime updateTime;
  int size;
  bool isDirectory;
  bool isComprssFile;
  bool isShare;
  int fileNum;

  DirectoryCO();

  factory DirectoryCO.fromJson(Map<String, dynamic> json) => _$DirectoryCOFromJson(json);

  Map<String, dynamic> toJson() => _$DirectoryCOToJson(this);

//  var filename: String? = null
//  var updateTime: Date? = null
//  var size: Long? = null
//  public var isDirectory = false
//  public var isCompressFile = false
//  public var isShare = false
//  public var fileNum = 0//如果是压缩文件里面有多少文件，如果是目录，里面有多少文件
}
