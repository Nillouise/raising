import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class Smb {
  static const MethodChannel methodChannel = MethodChannel('nil/channel');
  static Map<String, Smb> smbMap = Map<String, Smb>();
  String hostname;
  String shareName;
  String domain;
  String username;
  String password;
  String path;
  String searchPattern;

  Smb({
    @required this.hostname,
    @required this.shareName,
    @required this.domain,
    @required this.username,
    @required this.password,
    @required this.path,
    @required this.searchPattern,
  });

  static void pushConfig(
      String configName,
      String hostname,
      String shareName,
      String domain,
      String username,
      String password,
      String path,
      String searchPattern) {
    smbMap[configName] = Smb(
        hostname: hostname,
        shareName: shareName,
        domain: domain,
        username: username,
        password: password,
        path: path,
        searchPattern: searchPattern);
  }

  static Smb getConfig(String configName) {
    return smbMap[configName];
  }

  Future<List> smbList() async {
    try {
      final List result = await methodChannel.invokeMethod('smbList', {
        "hostname": hostname,
        "shareName": shareName,
        "domain": domain,
        "username": username,
        "password": password,
        "path": path,
        "searchPattern": searchPattern
      });
      return result;
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
    } catch (e) {
      logger.e(e);
    }
  }

  Future<Uint8List> getFile(String filename) async {
    try {
      final Uint8List result = await methodChannel.invokeMethod('getFile', {
        "hostname": hostname,
        "shareName": shareName,
        "domain": domain,
        "username": username,
        "password": password,
        "path": path + "/" + filename,
        "searchPattern": searchPattern
      });
      return result;
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
    } catch (e) {
      logger.e(e);
    }
  }
}
