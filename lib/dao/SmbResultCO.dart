//还没能配合SmbChannel，java代码层弃用
class SmbResultCO {
  String msg;
  dynamic result;

  SmbResultCO();

  factory SmbResultCO.fromJson(Map<String, dynamic> json) => throw UnimplementedError();

  Map<String, dynamic> toJson() => throw UnimplementedError();

  static String successful = "successful";
  static String emptyIndex = "empty indexs";
  static String cancel = "cancel";
  static String containNotExistIndex = "contain not exist index";
  static String unknownError = "unknown error";
}
