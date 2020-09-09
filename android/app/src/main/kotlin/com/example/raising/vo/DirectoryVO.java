//package com.example.raising.vo;
//
//import com.google.gson.Gson;
//
//import java.util.Date;
//import java.util.HashMap;
//
//import lombok.Data;
//import lombok.experimental.Accessors;
//
//@Data
//@Accessors(chain = true)
//public class DirectoryVO {
//    static Gson gson = new Gson();
//
//    private String filename;
//    private Date updateTime;
//    private boolean isDirectory;
//    private boolean isCompressFile;
//    private boolean isShare;
//    int fileNum; //如果是压缩文件里面有多少文件，如果是目录，里面有多少文件
//    private Long size;
//
//    @Override
//    public String toString() {
//        return gson.toJson(this);
//    }
//
//
//
//
//}
