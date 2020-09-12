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

@JsonSerializable()
class FileInfoPO {
  String smbId;
  String smbNickName; //只用smbId可能无法恢复删除的smb链接,所以也存储一下这个nickName
  String absPath; //include filename
  String filename;
  DateTime updateTime;
  int size;
  bool isDirectory;
  bool isComprssFile;
  bool isShare;

  int readLenght; //已经看了多少页
  int fileNum;

  FileInfoPO();

  factory FileInfoPO.fromJson(Map<String, dynamic> json) => _$FileInfoPOFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoPOToJson(this);
}

@JsonSerializable()
class FileContentCO {
  String absFilename; //压缩文件名字
  String zipAbsFilename; //压缩文件内的绝对路径
  int index;
  int length; //整个压缩文件内的文件的数量。
  dynamic content;

  FileContentCO();

  factory FileContentCO.fromJson(Map<String, dynamic> json) => _$ZipFileContentCOFromJson(json);

  Map<String, dynamic> toJson() => _$ZipFileContentCOToJson(this);
}
