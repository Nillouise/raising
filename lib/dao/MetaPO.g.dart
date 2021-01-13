// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MetaPO.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MetaPo _$MetaPoFromJson(Map json) {
  return MetaPo()
    ..key = json['key'] as String
    ..fileKeyScoreChangeDay = const CustomDateTimeConverter()
        .fromJson(json['fileKeyScoreChangeDay'] as int)
    ..searchHistory = (json['searchHistory'] as List)
        ?.map((e) => e == null
            ? null
            : SearchHistory.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList()
    ..hosts = (json['hosts'] as List)
        ?.map((e) => e == null
            ? null
            : HostPO.fromJson((e as Map)?.map(
                (k, e) => MapEntry(k as String, e),
              )))
        ?.toList();
}

Map<String, dynamic> _$MetaPoToJson(MetaPo instance) => <String, dynamic>{
      'key': instance.key,
      'fileKeyScoreChangeDay': const CustomDateTimeConverter()
          .toJson(instance.fileKeyScoreChangeDay),
      'searchHistory': instance.searchHistory,
      'hosts': instance.hosts,
    };

SearchHistory _$SearchHistoryFromJson(Map json) {
  return SearchHistory(
    json['keyword'] as String,
    const CustomDateTimeConverter().fromJson(json['searchTime'] as int),
  );
}

Map<String, dynamic> _$SearchHistoryToJson(SearchHistory instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'searchTime': const CustomDateTimeConverter().toJson(instance.searchTime),
    };
