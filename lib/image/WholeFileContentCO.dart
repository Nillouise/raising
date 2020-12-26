import 'dart:typed_data';

class WholeFileContentCO {
  String msg;
  String error;
  String absPath; //总是包括filename(如果是文件夹，则包括到文件夹名），只有当没有absPath时，再去查filename字段
  String filename;
  Uint8List content;
  int size;
  bool isDirectory = false;
  DateTime createTime;
  DateTime updateTime;
}
