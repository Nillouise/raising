import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:raising/image/cache.dart';
import 'dart:convert';

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
}

/**
    {
    "smbId":"value",
    "smbNickName":"smbNickName",
    "absPath":"value",
    "filename":"value",
    "updateTime":"2018-09-06 15:03:48",
    "size":5,
    "isDirectory":true,
    "isCompressFile":true,
    "isShare":true,
    "readLenght":5,
    "fileNum":5,
    "recentReadTime":"2018-09-06 15:03:48"
    }
 */
FileInfoPo fileInfoPoFromJson(String str) => FileInfoPo.fromJson(json.decode(str));

String fileInfoPoToJson(FileInfoPo data) => json.encode(data.toJson());

class FileInfoPo {
  FileInfoPo({
    this.smbId,
    this.smbNickName,
    this.absPath,
    this.filename,
    this.updateTime,
    this.size,
    this.isDirectory,
    this.isCompressFile,
    this.isShare,
    this.readLenght,
    this.fileNum,
    this.recentReadTime,
  });

  String smbId;
  String smbNickName;
  String absPath;
  String filename;
  DateTime updateTime;
  int size;
  bool isDirectory;
  bool isCompressFile;
  bool isShare;
  int readLenght;
  int fileNum;
  DateTime recentReadTime;

  factory FileInfoPo.fromJson(Map<String, dynamic> json) => FileInfoPo(
    smbId: json["smbId"],
    smbNickName: json["smbNickName"],
    absPath: json["absPath"],
    filename: json["filename"],
    updateTime: DateTime.parse(json["updateTime"]),
    size: json["size"],
    isDirectory: json["isDirectory"],
    isCompressFile: json["isCompressFile"],
    isShare: json["isShare"],
    readLenght: json["readLenght"],
    fileNum: json["fileNum"],
    recentReadTime: DateTime.parse(json["recentReadTime"]),
  );

  Map<String, dynamic> toJson() => {
    "smbId": smbId,
    "smbNickName": smbNickName,
    "absPath": absPath,
    "filename": filename,
    "updateTime": updateTime.toIso8601String(),
    "size": size,
    "isDirectory": isDirectory,
    "isCompressFile": isCompressFile,
    "isShare": isShare,
    "readLenght": readLenght,
    "fileNum": fileNum,
    "recentReadTime": recentReadTime.toIso8601String(),
  };
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
  bool isCompressFile;
  bool isShare;

  int readLenght; //已经看了多少页
  int fileNum;

  FileInfoPO();

  FileInfoPO copyFromFileContentCO(FileContentCO co) {
    this
      ..absPath = co.absFilename
      ..size = co.wholeFileSize
      ..fileNum = co.length
      ..filename = p.basename(co.absFilename ?? "");
  }

  factory FileInfoPO.fromJson(Map<String, dynamic> json) => _$FileInfoPOFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoPOToJson(this);
}

@JsonSerializable()
class FileContentCO implements CacheContent {
  String absFilename; //压缩文件名字
  String zipAbsFilename; //压缩文件内的绝对路径
  int index;
  int length; //整个压缩文件内的文件的数量。
  int wholeFileSize; // 整个文件，而不是压缩文件内的文件，的大小
  dynamic content;

  FileContentCO();

  factory FileContentCO.fromJson(Map<String, dynamic> json) => _$ZipFileContentCOFromJson(json);

  Map<String, dynamic> toJson() => _$ZipFileContentCOToJson(this);

  @override
  Uint8List getCacheFile() {
    return content;
  }
}


/**
    {
    "filename":"value",
    "star":5,
    "score14":5.0,
    "score60":5.0,
    "recentReadTime":"2018-09-06 15:03:48"
    }
 */

FileKeyPo fileKeyPoFromJson(String str) => FileKeyPo.fromJson(json.decode(str));

String fileKeyPoToJson(FileKeyPo data) => json.encode(data.toJson());

class FileKeyPo {
  FileKeyPo({
    this.filename,
    this.star,
    this.score14,
    this.score60,
    this.recentReadTime,
  });

  String filename;
  int star;
  int score14;
  int score60;
  DateTime recentReadTime;

  factory FileKeyPo.fromJson(Map<String, dynamic> json) => FileKeyPo(
    filename: json["filename"],
    star: json["star"],
    score14: json["score14"],
    score60: json["score60"],
    recentReadTime: DateTime.parse(json["recentReadTime"]),
  );

  Map<String, dynamic> toJson() => {
    "filename": filename,
    "star": star,
    "score14": score14,
    "score60": score60,
    "recentReadTime": recentReadTime.toIso8601String(),
  };
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

  FileKeyPO(this.filename, this.tags, this.star, this.clickTimes, this.readTimes);

  factory FileKeyPO.fromJson(Map<String, dynamic> json) => _$FileKeyPOFromJson(json);

  Map<String, dynamic> toJson() => _$FileKeyPOToJson(this);
}
