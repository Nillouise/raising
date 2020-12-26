class ExploreCO {
  String absPath; //总是包括filename(如果是文件夹，则包括到文件夹名），只有当没有absPath时，再去查filename字段
  String filename;
  int size;
  int fileNum; //如果是压缩文件里面有多少文件，如果是目录，里面有多少文件
  bool isDirectory = false;
  DateTime createTime;
  DateTime updateTime;
}
