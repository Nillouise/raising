package com.example.raising.vo

import java.util.*
import kotlin.collections.HashMap

/**
 * �ҵ�����ַ��˴�������extract �����ļ�����Ϣ�����п����ܻ�ȡ��ԭ������Ҫ����Ϣ������ѹ���ļ�������֣�����Щ��Ϣ�ֿ�����ĳ���ط�����
 * ��ʹ���ڽ�ѹ���ǵ�����Ҳ�������������⣬Ϊ�˲��˷�ʱ�����ش�һ�Σ�
 * ��Ƶ�ExtractCOӦ�ò����ϸ�֤�ܻ�ȡ��ʲô�������ݣ������ܻ�ȡ��ʲô������ʲô��ȥ����Ȼ���ֶε�����Ҫ�й淶��
 * ���⣬����ѹ���ļ������������޵ģ�������������Ӧ��ûʲô���⡣
 */
class ExtractCO {
    var msg: String = "OK";
    var error: String = "";
    var absPath: String? = null;//���ǰ���filename(������ļ��У���������ļ���������ֻ�е�û��absPathʱ����ȥ��filename�ֶ�
    var filename: String? = null;
    var size: Long? = null;
    var fileNum: Int? = null;//�����ѹ���ļ������ж����ļ��������Ŀ¼�������ж����ļ�
    var isDirectory = false
    var isCompressFile = false
    var createTime: Date? = null
    var updateTime: Date? = null
    var compressFormat: String? = null;

    //index ���ļ���������·�����򣬵ڼ����ļ��������ļ��У���������ţ���0��ʼ��
    var indexPath: HashMap<Int, String>? = null;//ѹ���ļ��ڵľ���·��
    var indexContent: HashMap<Int, ByteArray>? = null;

    fun getMap(): HashMap<String, Any> {
        val cur = HashMap<String, Any?>();

        cur["msg"] = msg;
        cur["error"] = error;
        cur["absPath"] = absPath
        cur["filename"] = filename
        cur["size"] = size;
        cur["fileNum"] = fileNum;
        cur["isDirectory"] = isDirectory;
        cur["isCompressFile"] = isCompressFile;
        cur["createTime"] = createTime?.time;
        cur["updateTime"] = updateTime?.time;
        cur["compressFormat"] = compressFormat;
        cur["indexPath"] = indexPath;
        cur["indexContent"] = indexContent;

        val res = HashMap<String, Any>();
        cur.forEach {
            if (it.value != null) {
                res[it.key] = it.value!!
            }
        }
        return res;
    }

}
