import 'package:logger/logger.dart';
import 'package:raising/model/HostModel.dart';

//这几个vo还没能清楚相关使用，，但在dart层已经弃用完成（只要删除smbchannel，repository即可）,这里已经可以不管了
var logger = Logger();

class SmbPO {
  String id;
  String _nickName;
  String hostname; //maybe include the path

  String domain;
  String username;
  String password;

  static void copySmbPO(SmbPO source, SmbPO target) {
    target
      ..id = source.id
      .._nickName = source._nickName
      ..hostname = source.hostname
      ..domain = source.domain
      ..username = source.username
      ..password = source.password;
  }

  String get onlyHostname {
    if (hostname != null && hostname.contains(":")) {
      return hostname.split(":")[0];
    } else {
      return hostname;
    }
  }

  String get hostnamePath {
    if (hostname != null && hostname.contains(":")) {
      return hostname.split(":")[1];
    } else {
      return "";
    }
  }

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

  SmbPO();

  factory SmbPO.fromJson(Map<String, dynamic> json) {
    return SmbPO()
      ..id = json['id'] as String
      .._nickName = json['_nickName'] as String
      ..hostname = json['hostname'] as String
      ..domain = json['domain'] as String
      ..username = json['username'] as String
      ..password = json['password'] as String;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      '_nickName': _nickName,
      'hostname': hostname,
      'domain': domain,
      'username': username,
      'password': password,
    };
  }
}

class SmbVO extends SmbPO {
  String absPath;

  static SmbVO copyFromSmbPO(SmbPO po) {
    SmbVO res = SmbVO();
    SmbPO.copySmbPO(po, res);
    return res;
  }

  SmbVO copy() {
    var vo = copyFromSmbPO(this);
    vo.absPath = this.absPath;
    return vo;
  }

  HostPO toHostPO() {
    return HostPO()
      ..id = id
      ..nickName = _nickName
      ..hostname = hostname
      ..domain = domain
      ..username = username
      ..password = password
      ..type = "smb";
  }
}

//用在channel上交互产生
class SmbCO {
  String hostname; //combine with path
  String domain;
  String username;
  String password;
  String absPath;

  SmbCO.copyFrom(SmbVO vo) {
    this.hostname = vo.onlyHostname;
    this.password = vo.password;
    this.domain = vo.domain;
    this.username = vo.username;
    this.absPath = vo.absPath;
  }

  Map toMap() {
    return {"hostname": hostname, "domain": domain, "username": username, "password": password, "absPath": absPath};
  }
}


