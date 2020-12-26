import 'dart:typed_data';

class ExtractCO {
  String msg;
  String error;
  String absPath; //���ǰ���filename(������ļ��У���������ļ���������ֻ�е�û��absPathʱ����ȥ��filename�ֶ�
  String filename;
  int size;
  int fileNum; //�����ѹ���ļ������ж����ļ��������Ŀ¼�������ж����ļ�
  bool isDirectory = false;
  bool isCompressFile = false;
  DateTime createTime;
  DateTime updateTime;
  String compressFormat;

  //index ���ļ���������·�����򣬵ڼ����ļ��������ļ��У���������ţ���0��ʼ��
  Map<int, String> indexPath; //ѹ���ļ��ڵľ���·��
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
