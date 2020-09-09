package com.example.raising.vo

import com.google.gson.Gson
import java.util.*
import kotlin.collections.HashMap


class DirectoryVO : GetMapInterface {
    public var filename: String? = null
    public var updateTime: Date? = null
    public var size: Long? = null
    public var isDirectory = false
    public var isCompressFile = false
    public var isShare = false
    public var fileNum = 0//如果是压缩文件里面有多少文件，如果是目录，里面有多少文件


    companion object {
        var gson = Gson()
    }


    override fun getMap(): HashMap<String, Any?> {
        val res = HashMap<String, Any?>();
        if (filename != null) {
            res["filename"] = filename
        }
        if (updateTime != null) {
            res["updateTime"] = updateTime!!.time;
        }
        if (isDirectory != null) {
            res["isDirectory"] = isDirectory;
        }
        if (isCompressFile != null) {
            res["isCompressFile"] = isCompressFile;
        }
        if (isShare != null) {
            res["isShare"] = isShare;
        }
        if (fileNum != null) {
            res["fileNum"] = fileNum;
        }
        if (size != null) {
            res["size"] = size;
        }

        return res;
    }

    override fun toString(): String {
        return gson.toJson(this)
    }
}
