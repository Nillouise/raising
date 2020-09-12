import 'package:json_annotation/json_annotation.dart';

part 'SmbResultCO.g.dart';

@JsonSerializable()
class SmbResultCO {
  String msg;
  dynamic result;

  SmbResultCO();

  factory SmbResultCO.fromJson(Map<String, dynamic> json) => _$SmbResultCOFromJson(json);

  Map<String, dynamic> toJson() => _$SmbResultCOToJson(this);

  static String successful = "successful";
  static String emptyIndex = "empty indexs";
  static String cancel = "cancel";
  static String containNotExistIndex = "contain not exist index";
  static String unknownError = "unknown error";
}
