import 'package:json_annotation/json_annotation.dart';

part 'SmbResultCO.g.dart';

@JsonSerializable()
class SmbResult {
  String msg;
  dynamic result;

  SmbResult();

  factory SmbResult.fromJson(Map<String, dynamic> json) => _$SmbResultFromJson(json);

  Map<String, dynamic> toJson() => _$SmbResultToJson(this);

  static String successful = "successful";
  static String emptyIndex = "empty indexs";
  static String cancel = "cancel";
  static String containNotExistIndex = "contain not exist index";
  static String unknownError = "unknown error";
}
