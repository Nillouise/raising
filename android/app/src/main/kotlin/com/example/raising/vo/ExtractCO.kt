package com.example.raising.vo

import java.util.*
import kotlin.collections.HashMap

/**
 * 我的设计又犯了错误，由于extract 网络文件的信息，很有可能能获取到原本不需要的信息，比如压缩文件里的名字，但这些信息又可能在某个地方有用
 * 即使是在解压他们的内容也会有这样的问题，为了不浪费时间再重传一次，
 * 设计的ExtractCO应该不再严格保证能获取到什么样的内容，而是能获取到什么，就塞什么进去，当然，字段的命名要有规范。
 * 另外，由于压缩文件的属性是有限的，所以这种做法应该没什么问题。
 */
class ExtractCO {
    var msg: String = "OK";
    var error: String = "";
    var absPath: String? = null;//总是包括filename(如果是文件夹，则包括到文件夹名），只有当没有absPath时，再去查filename字段
    var filename: String? = null;
    var size: Long? = null;
    var fileNum: Int? = null;//如果是压缩文件里面有多少文件，如果是目录，里面有多少文件
    var isDirectory = false
    var isCompressFile = false
    var createTime: Date? = null
    var updateTime: Date? = null
    var compressFormat: String? = null;

    //index 按文件名（包括路径排序，第几个文件，跳过文件夹）的排序序号，从0开始。
    var indexPath: HashMap<Int, String>? = null;//压缩文件内的绝对路径
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
