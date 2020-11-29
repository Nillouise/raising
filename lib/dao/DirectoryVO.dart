import 'dart:convert';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart' as p;
import 'package:raising/dao/SmbVO.dart';
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

  factory DirectoryCO.fromJson(Map<String, dynamic> json) => _$DirectoryCOFromJson(json);

  Map<String, dynamic> toJson() => _$DirectoryCOToJson(this);
}

class SearchingCO {
  DirectoryCO directoryCO;
  SmbVO smbVO;

  SearchingCO(this.directoryCO, this.smbVO);
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
//FileInfoPO fileInfoPoFromJson(String str) => FileInfoPO.fromJson(json.decode(str));
//
//String fileInfoPoToJson(FileInfoPO data) => json.encode(data.toJson());
//
//class FileInfoPO {
//  FileInfoPO({
//    this.smbId,
//    this.smbNickName,
//    this.absPath,
//    this.filename,
//    this.updateTime,
//    this.size,
//    this.isDirectory,
//    this.isCompressFile,
//    this.isShare,
//    this.readLenght,
//    this.fileNum,
//    this.recentReadTime,
//  });
//
//  String smbId;
//  String smbNickName;
//  String absPath;
//  String filename;
//  DateTime updateTime;
//  int size;
//  bool isDirectory;
//  bool isCompressFile;
//  bool isShare;
//  int readLenght;
//  int fileNum;
//  DateTime recentReadTime;
//
//  factory FileInfoPO.fromJson(Map<String, dynamic> json) => FileInfoPO(
//        smbId: json["smbId"],
//        smbNickName: json["smbNickName"],
//        absPath: json["absPath"],
//        filename: json["filename"],
//        updateTime: DateTime.parse(json["updateTime"]),
//        size: json["size"],
//        isDirectory: json["isDirectory"],
//        isCompressFile: json["isCompressFile"],
//        isShare: json["isShare"],
//        readLenght: json["readLenght"],
//        fileNum: json["fileNum"],
//        recentReadTime: DateTime.parse(json["recentReadTime"]),
//      );
//
//  Map<String, dynamic> toJson() => {
//        "smbId": smbId,
//        "smbNickName": smbNickName,
//        "absPath": absPath,
//        "filename": filename,
//        "updateTime": updateTime.toIso8601String(),
//        "size": size,
//        "isDirectory": isDirectory,
//        "isCompressFile": isCompressFile,
//        "isShare": isShare,
//        "readLenght": readLenght,
//        "fileNum": fileNum,
//        "recentReadTime": recentReadTime.toIso8601String(),
//      };
//}

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
  DateTime recentReadTime;

  FileInfoPO();

  FileInfoPO copyFromFileContentCO(FileContentCO co) {
    this
      ..absPath = co.absFilename
      ..size = co.wholeFileSize
      ..fileNum = co.length
      ..filename = p.basename(co.absFilename ?? "");
  }

  FileInfoPO.create(
      {this.smbId,
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
      this.recentReadTime});

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
    "score14":5.1,
    "score60":5.1,
    "recentReadTime":"2018-09-06 15:03:48"
    }
 */

FileKeyPO fileKeyPoFromJson(String str) => FileKeyPO.fromJson(json.decode(str));

String fileKeyPoToJson(FileKeyPO data) => json.encode(data.toJson());

class FileKeyPO {
  FileKeyPO({
    this.filename,
    this.star,
    this.score14,
    this.score60,
    this.recentReadTime,
  });

  String filename;
  int star;
  double score14;
  double score60;
  DateTime recentReadTime;
  factory FileKeyPO.fromJson(Map<String, dynamic> json) => FileKeyPO(
        filename: json["filename"],
        star: json["star"],
        score14: json["score14"],
        score60: json["score60"],
        recentReadTime: DateTime.fromMillisecondsSinceEpoch(json["recentReadTime"] ?? 0),
      );

  Map<String, dynamic> toJson() => {
        "filename": filename,
        "star": star,
        "score14": score14,
        "score60": score60,
        "recentReadTime": recentReadTime.millisecondsSinceEpoch,
      };
}

//@JsonSerializable()
//class FileKeyPO {
//  String filename; //唯一索引，以后可能会加上md5之类的文件唯一标识
//  Map<String, String> tags;
//  int star;
//
//  //什么时候点击了
//  List<DateTime> clickTimes = new List<DateTime>();
//
//  //按秒算，这次看了多少时间，应当跟clickTimes一起保存
//  List<int> readTimes;
//
//  FileKeyPO(this.filename, this.tags, this.star, this.clickTimes, this.readTimes);
//
//  factory FileKeyPO.fromJson(Map<String, dynamic> json) => _$FileKeyPOFromJson(json);
//
//  Map<String, dynamic> toJson() => _$FileKeyPOToJson(this);
//}
