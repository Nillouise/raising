package com.example.raising.vo

import java.util.*

class ExploreCO {
    /**
     * 注意，absPath实测在webdav中，会被url编码（但filename却不会），所以这里涉及absPath的需要处理好
     * 一般来说不需要注意，但搜索时，可能需要先转换好url encode才行，又或者需要显示absPath，就需要被urlDecode。
     */
    var absPath: String = ""; //总是包括filename(如果是文件夹，则包括到文件夹名），只有当没有absPath时，再去查filename字段
    var filename: String = "";
    var size: Long = 0;
    var fileNum: Int? = null; //如果是压缩文件里面有多少文件，如果是目录，里面有多少文件
    var isDirectory: Boolean = false;
    var createTime: Date? = null;
    var updateTime: Date? = null;

    fun toMap(): Map<String, *> {
        return hashMapOf(
                "absPath" to absPath,
                "filename" to filename,
                "size" to size,
                "fileNum" to fileNum,
                "isDirectory" to isDirectory,
                "createTime" to createTime?.time,
                "updateTime" to updateTime?.time
        )

    }

}