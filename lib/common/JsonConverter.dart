import 'dart:core';
import 'dart:typed_data';
import 'dart:typed_data';

import 'package:json_annotation/json_annotation.dart';

class CustomDateTimeConverter implements JsonConverter<DateTime, int> {
  const CustomDateTimeConverter();

  @override
  DateTime fromJson(int json) => json == null ? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(json);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

class MapIntStringConverter implements JsonConverter<Map<int, Uint8List>, Map<int, Uint8List>> {
  const MapIntStringConverter();

  @override
  Map<int, Uint8List> fromJson(Map<int, Uint8List> json) => json == null ? Map<int, Uint8List>() : json;

  @override
  Map<int, Uint8List> toJson(Map<int, Uint8List> object) => object;
}
