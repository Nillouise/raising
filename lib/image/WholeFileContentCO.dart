import 'dart:typed_data';

class WholeFileContentCO {
  String msg;
  String error;
  String absPath; //���ǰ���filename(������ļ��У���������ļ���������ֻ�е�û��absPathʱ����ȥ��filename�ֶ�
  String filename;
  Uint8List content;
  int size;
  bool isDirectory = false;
  DateTime createTime;
  DateTime updateTime;
}
