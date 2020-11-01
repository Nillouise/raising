// To parse this JSON data, do
//
//     final metaPo = metaPoFromJson(jsonString);

import 'dart:convert';

/**
 * 使用https://app.quicktype.io/生成：
    {
    "key":"value",
    "fileKeyScoreChangeDay":"2018-09-06 15:03:48"
    }
 *
 *
 */

MetaPo metaPoFromJson(String str) => MetaPo.fromJson(json.decode(str));

String metaPoToJson(MetaPo data) => json.encode(data.toJson());

class MetaPo {
  MetaPo({
    this.key,
    this.fileKeyScoreChangeDay,
  });

  String key;
  DateTime fileKeyScoreChangeDay;

  factory MetaPo.fromJson(Map<String, dynamic> json) => MetaPo(
    key: json["key"],
    fileKeyScoreChangeDay: DateTime.parse(json["fileKeyScoreChangeDay"]),
  );

  Map<String, dynamic> toJson() => {
    "key": key,
    "fileKeyScoreChangeDay": fileKeyScoreChangeDay.toIso8601String(),
  };
}
