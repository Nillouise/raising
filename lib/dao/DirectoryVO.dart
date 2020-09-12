import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:raising/image/cache.dart';

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

  factory DirectoryCO.fromJson(Map<String, dynamic> json) =>
      _$DirectoryCOFromJson(json);

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

  factory FileInfoPO.fromJson(Map<String, dynamic> json) =>
      _$FileInfoPOFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoPOToJson(this);
}

@JsonSerializable()
class FileContentCO implements CacheContent {
  String absFilename; //压缩文件名字
  String zipAbsFilename; //压缩文件内的绝对路径
  int index;
  int length; //整个压缩文件内的文件的数量。
  dynamic content;

  FileContentCO();

  factory FileContentCO.fromJson(Map<String, dynamic> json) =>
      _$ZipFileContentCOFromJson(json);

  Map<String, dynamic> toJson() => _$ZipFileContentCOToJson(this);

  @override
  Uint8List getCacheFile() {
    return content;
  }
}

@JsonSerializable()
class FileKeyPO {
  String filename; //唯一索引，以后可能会加上md5之类的文件唯一标识
  Map<String, String> tags;
  int star;

  //什么时候点击了
  List<DateTime> clickTimes = new List<DateTime>();

  //按秒算，这次看了多少时间，应当跟clickTimes一起保存
  List<int> readTimes;

  FileKeyPO(
      this.filename, this.tags, this.star, this.clickTimes, this.readTimes);

  factory FileKeyPO.fromJson(Map<String, dynamic> json) =>
      _$FileKeyPOFromJson(json);

  Map<String, dynamic> toJson() => _$FileKeyPOToJson(this);
}
