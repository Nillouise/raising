import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as p;
import 'package:raising/exception/SmbException.dart';
import 'package:raising/model/file_info.dart';

import '../util.dart';

part 'Smb.g.dart';

var logger = Logger();

@JsonSerializable()
class Smb {
  static const MethodChannel methodChannel = MethodChannel('nil/channel');
  static Map<String, Smb> smbMap = Map<String, Smb>();
  static Smb currentSmb;
  String id;
  String _nickName;
  String hostname;

  String get nickName {
    if (_nickName == null) {
      if (id == null) {
        return "error id";
      } else {
        _nickName = id.split("##~##")[0];
      }
    }
    return _nickName;
  }

  set nickName(String x) {
    _nickName = x;
  }

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

  factory Smb.fromJson(Map<String, dynamic> json) => _$SmbFromJson(json);

  Map<String, dynamic> toJson() => _$SmbToJson(this);

  Future<Void> init() async {
    //valid field;
    shareName = "";
    domain = "";
    if (p.split(hostname).length > 1) {
      path = p.joinAll(p.split(hostname).sublist(1));
    } else {
      path = "";
    }
    searchPattern = searchPattern ?? "*";

    try {
      await methodChannel.invokeMethod('init',
          {"hostname": p.split(hostname)[0], "shareName": shareName, "domain": domain, "username": username, "password": password, "path": path, "searchPattern": searchPattern});
      currentSmb = this;
      return null;
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }

  void test() async {
    print("dart test");
    await methodChannel.invokeMethod(
        \'test\', {"hostname": hostname, "shareName": shareName, "domain": domain, "username": username, "password": password, "path": path, "searchPattern": searchPattern});
  }

  static Future<Void> pushConfig(String configName, String hostname, String shareName, String domain, String username, String password, String path, String searchPattern) async {
    if (!smbMap.containsKey(configName)) {
      var smb = Smb(hostname: hostname, shareName: shareName, domain: domain, username: username, password: password, path: path, searchPattern: searchPattern);
      smb.init();
      smbMap[configName] = smb;
      return null;
    }
  }

  static Smb getConfig(String configName) {
    return smbMap[configName];
  }

  static Smb getCurrentSmb() {
    return currentSmb;
  }

  Future<List<String>> listShares() async {
    try {
      List<dynamic> list = await methodChannel.invokeMethod('listShares');
      return List<String>.from(list)..removeWhere((element) => Utils.invalidFilename(element));
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }

  Future<List<FileInfo>> listFiles(String share, String path, String searchPattern) async {
    try {
      final String result = await methodChannel.invokeMethod(\'listFiles\', {"path": path, "searchPattern": searchPattern, "share": share});
      List decode = json.decode(result);
      List<FileInfo> list = decode.map((element) => FileInfo.fromJson(element)).toList();
      return list
        ..removeWhere((element) => element.filename == '..' || element.filename == '.')
        ..map((x) {
          x.absPath = p.join(path, x.filename);
          return x;
        }).toList()
        ..sort((a, b) {
          if (b.updateTime == null || a.updateTime == null) {
            return b.filename.compareTo(a.filename);
          } else {
            return b.updateTime.compareTo(a.updateTime);
          }
        });
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
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
