import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class Smb {
  static const MethodChannel methodChannel = MethodChannel('nil/channel');
  static Map<String, Smb> smbMap = Map<String, Smb>()..putIfAbsent("[C]", ()=> Smb()..id = "[C]");
  String id;
  String hostname;
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
  });

  Future<Void> init() async {
    try {
      await methodChannel.invokeMethod('init', {
        "hostname": hostname,
        "shareName": shareName,
        "domain": domain,
        "username": username,
        "password": password,
        "path": path,
        "searchPattern": searchPattern
      });
      return null;
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }

  static Future<Void> pushConfig(
      String configName,
      String hostname,
      String shareName,
      String domain,
      String username,
      String password,
      String path,
      String searchPattern) async {
    if (!smbMap.containsKey(configName)) {
      var smb = Smb(
          hostname: hostname,
          shareName: shareName,
          domain: domain,
          username: username,
          password: password,
          path: path,
          searchPattern: searchPattern);
      smb.init();
      smbMap[configName] = smb;
      return null;
    }
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
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }

  Future<List> listFiles(String path, String searchPattern) async {
    try {
      final List result = await methodChannel.invokeMethod(
          'listFiles', {"path": path, "searchPattern": searchPattern});
      return result;
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
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
        "path": filename,
        "searchPattern": searchPattern
      });
      return result;
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
    } catch (e) {
      logger.e(e);
    }
  }

  Future<List<String>> listZip(String filename) async {
    try {
      final List<String> res = await methodChannel.invokeMethod('listZip', {
        "hostname": hostname,
        "shareName": shareName,
        "domain": domain,
        "username": username,
        "password": password,
        "path": filename,
        "searchPattern": searchPattern
      });
      return res;
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
    } catch (e) {
      logger.e(e);
    }
  }

  Future<Map<dynamic, dynamic>> previewFiles(List<String> absFilenames) async {
    try {
      final Map res = await methodChannel
          .invokeMethod('previewFiles', {"absFilenames": absFilenames});
      return res;
    } on PlatformException catch (e) {
      logger.e("PlatformException {}", e);
      throw e;
    } catch (e) {
      logger.e(e);
      throw e;
    }
  }
}
