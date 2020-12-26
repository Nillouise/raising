import 'dart:typed_data';

class ExtractCO {
  String msg;
  String error;
  String absPath; //总是包括filename(如果是文件夹，则包括到文件夹名），只有当没有absPath时，再去查filename字段
  String filename;
  int size;
  int fileNum; //如果是压缩文件里面有多少文件，如果是目录，里面有多少文件
  bool isDirectory = false;
  bool isCompressFile = false;
  DateTime createTime;
  DateTime updateTime;
  String compressFormat;

  //index 按文件名（包括路径排序，第几个文件，跳过文件夹）的排序序号，从0开始。
  Map<int, String> indexPath; //压缩文件内的绝对路径
  Map<int, Uint8List> indexContent;

  factory ExtractCO.fromJson(Map<String, dynamic> json) {
    return ExtractCO()
      ..msg = json['msg'] as String
      ..error = json['error'] as String
      ..absPath = json['absPath'] as String
      ..filename = json['filename'] as String
      ..size = json['size'] as int
      ..fileNum = json['fileNum'] as int
      ..isDirectory = json['isDirectory'] as bool
      ..isCompressFile = json['isCompressFile'] as bool
      ..createTime = json['createTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['createTime'])
      ..updateTime = json['updateTime'] == null ? null : DateTime.fromMillisecondsSinceEpoch(json['updateTime'])
      ..compressFormat = json['compressFormat'] as String
      ..indexPath = new Map<int, String>.from(json['indexPath'])
      ..indexContent = new Map<int, Uint8List>.from(json['indexContent']);
  }

  ExtractCO();
}
