import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:raising/exception/SmbException.dart';
import 'package:raising/model/file_info.dart';

part 'Smb.g.dart';

var logger = Logger();

@JsonSerializable()
class Smb {
  static const MethodChannel methodChannel = MethodChannel('nil/channel');
  static Map<String, Smb> smbMap = Map<String, Smb>();
  static Smb currentSmb;
  String id;
  String realNickName;
  String hostname;

  //deprecated
  String shareName;
  String domain;
  String username;
  String password;
  String path;
  String searchPattern;

  Smb({
    this.hostname,
    this.shareName,
    this.domain,
    this.username,
    this.password,
    this.path,
    this.searchPattern,
  }) {}

  String get nickName {
    if (realNickName == null) {
      if (id == null) {
        return "error id";
      } else {
        realNickName = id.split("##~##")[0];
      }
    }
    return realNickName;
  }

  set nickName(String x) {
    realNickName = x;
  }

  factory Smb.fromJson(Map<String, dynamic> json) => _$SmbFromJson(json);

  Map<String, dynamic> toJson() => _$SmbToJson(this);


  void test() async {
    print("dart test");
    await methodChannel.invokeMethod(
        "test", {"hostname": hostname, "shareName": shareName, "domain": domain, "username": username, "password": password, "path": path, "searchPattern": searchPattern});
  }

  static Smb getCurrentSmb() {
    return currentSmb;
  }

  Future<SmbHalfResult> loadImageFromIndex(String absFilename, int index, String share, {bool needFileDetailInfo = false}) async {
    try {
      final Map<dynamic, dynamic> loadImageFromIndex = await methodChannel.invokeMethod('loadImageFromIndex', {
        "absFilename": absFilename,
        "indexs": [index],
        "needFileDetailInfo": needFileDetailInfo,
        "share": share
      });
      SmbHalfResult res = SmbHalfResult.fromJson(new Map<String, dynamic>.from(loadImageFromIndex));

      if (res.msg == "successful") {
        if (res.result.containsKey(index)) {
          return res;
        } else {
          logger.e("loadImageFromIndex not contain key {}", res);
          throw SmbException("loadImageFromIndex failed");
        }
      } else {
        logger.e("loadImageFromIndex error {}", res);
        throw SmbException("loadImageFromIndex failed" + res.msg);
      }
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    }
  }

  Future<SmbHalfResult> loadImageFile(String absFilename, String share) async {
    try {
      final Map<dynamic, dynamic> loadImageFromIndex = await methodChannel.invokeMethod('loadImageFile', {"absFilename": absFilename, "share": share});
      SmbHalfResult res = SmbHalfResult.fromJson(new Map<String, dynamic>.from(loadImageFromIndex));

      if (res.msg == "successful") {
        if (res.result.containsKey(0)) {
          return res;
        } else {
          logger.e("loadImageFile not contain key {}", res);
          throw SmbException("loadImageFile failed");
        }
      } else {
        logger.e("loadImageFile error {}", res);
        throw SmbException("loadImageFromIndex failed" + res.msg);
      }
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    }
  }

  //此方法尽量不用
  Future<Uint8List> loadFilesFromIndexs(String filename, List<int> indexs, {bool needFileDetailInfo = false}) async {
    try {
      final Map<dynamic, dynamic> res = await methodChannel.invokeMethod('loadImageFromIndex', {"filename": filename, "indexs": indexs});
      //TODO:

    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    }
  }
}
