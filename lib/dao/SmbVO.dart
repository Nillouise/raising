import 'package:logger/logger.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/util.dart';

var logger = Logger();

class SmbPO {
  String id;
  String _nickName;
  String hostname; //maybe include the path

  String domain;
  String username;
  String password;

  SmbPO copySmbPO(SmbPO vo) {
    return vo
      ..id = this.id
      .._nickName = this._nickName
      ..hostname = this.hostname
      ..domain = this.domain
      ..username = this.username
      ..password = this.password;
  }

  String get onlyHostname {
    if (hostname != null && hostname.contains(":")) {
      return hostname.split(":")[0];
    } else {
      return hostname;
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
}

class SmbVO extends SmbPO {
  String _path;
  String wholePath; //include hostname'spath

  get path {
    return _path;
  }

  set path(x) {
    _path = x;
    if (hostname != null && hostname.contains(":")) {
      wholePath = Utils.joinPath(hostname.split(":")[1], x);
    } else {
      wholePath = x;
    }
  }

  static SmbVO fromSmb() {
    var smb = Smb.getCurrentSmb();
    return SmbVO()
      ..hostname = smb.hostname
      ..username = smb.username
      ..password = smb.password
      ..domain = smb.domain;
  }
}

//用在channel上交互产生
class SmbCO {
  String hostname; //combine with path
  String domain;
  String username;
  String password;
  String wholePath;

  SmbCO.copyFrom(SmbVO vo) {
    this.hostname = vo.onlyHostname;
    this.password = vo.password;
    this.domain = vo.domain;
    this.username = vo.username;
    this.wholePath = vo.wholePath;
  }

  Map toMap() {
    return {"hostname": hostname, "domain": domain, "username": username, "password": password, "wholePath": wholePath};
  }
}

class SmbSearchPO extends SmbVO {
  String searchPattern;
}
