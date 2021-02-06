import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';
import 'package:raising/common/JsonConverter.dart';
import 'package:raising/image/ExtractCO.dart';
import 'package:raising/image/cache.dart';
import 'package:raising/model/HostModel.dart';

part 'DirectoryVO.g.dart';

@JsonSerializable()
@CustomDateTimeConverter()
class SearchingCO {
  ExtractCO directoryCO;
  HostPO hostPO;

  SearchingCO(this.directoryCO, this.hostPO);
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

//stackoverflow.com/questions/52789217/flutter-parsing-json-with-datetime-from-golang-rfc3339-formatexception-invalid
//转换datetime
//TODO: 明天修复这个问题。
@JsonSerializable()
@CustomDateTimeConverter()
class FileInfoPO {
  String fileId; // 现在应当使用fileId来查找文件，将来用md5，filename之类的确认一个文件，目前fileId = filename
  String hostId;
  String hostNickName; //只用hostId可能无法恢复删除的smb链接,所以也存储一下这个nickName
  String absPath; //include filename
  String filename;
  DateTime updateTime;
  int size;
  bool isDirectory;
  bool isCompressFile;
  bool isShare;

  int fileNum;

  FileInfoPO();

  factory FileInfoPO.fromJson(Map<String, dynamic> json) => _$FileInfoPOFromJson(json);

  Map<String, dynamic> toJson() => _$FileInfoPOToJson(this);

  Map<String, dynamic> toIntJson() {
    Map map = this.toJson();
    for (var a in map.entries) {
      if (a.value is bool) {
        map[a.key] = a.value ? 1 : 0;
      }
    }
    return map;
  }

  factory FileInfoPO.fromIntJson(Map<String, dynamic> json) {
    var json2 = Map<String, dynamic>.from(json);
    if (json2["isDirectory"] != null) {
      json2["isDirectory"] = json2["isDirectory"] == 1;
    }

    if (json2["isCompressFile"] != null) {
      json2["isCompressFile"] = json2["isCompressFile"] == 1;
    }

    if (json2["isShare"] != null) {
      json2["isShare"] = json2["isShare"] == 1;
    }

    return FileInfoPO.fromJson(json2);
  }
}

//此类应该用来代表被点开过的操作的记录
@JsonSerializable()
@CustomDateTimeConverter()
class FileKeyPO {
  String fileId; // 现在应当使用fileId来查找文件，将来用md5，filename之类的确认一个文件，目前fileId = filename
  String filename;
  int star;
  double score14;
  double score60;
  DateTime recentReadTime;
  String comment;
  int readLength; //已经看了多少页

  factory FileKeyPO.fromJson(Map<String, dynamic> json) => _$FileKeyPOFromJson(json);

  Map<String, dynamic> toJson() => _$FileKeyPOToJson(this);

  FileKeyPO({this.fileId, this.filename, this.star, this.score14, this.score60, this.recentReadTime, this.comment, this.readLength});
}

class FileContentCO implements CacheContent {
  String absFilename; //压缩文件名字
  String zipAbsFilename; //压缩文件内的绝对路径
  int index;
  int length; //整个压缩文件内的文件的数量。
  int wholeFileSize; // 整个文件，而不是压缩文件内的文件，的大小

  dynamic content;

  FileContentCO();

  factory FileContentCO.fromJson(Map<String, dynamic> json) => throw UnimplementedError();

  Map<String, dynamic> toJson() => throw UnimplementedError();

  @override
  Uint8List getCacheFile() {
    return content;
  }
}

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
