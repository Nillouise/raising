import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';

var logger = Logger();

@JsonSerializable()
class SmbVO {
  String id;
  String _nickName;
  String hostname; //maybe include the path

  String domain;
  String username;
  String password;

  SmbVO({
    this.hostname,
    this.domain,
    this.username,
    this.password,
  });

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

class SmbPO extends SmbVO {
  String path;


}

//用在channel上交互产生
class SmbCO extends SmbPO {
  String wholePath; //include hostname,sharename,path

}

class SmbSearchPO extends SmbPO {
  String searchPattern;
}
