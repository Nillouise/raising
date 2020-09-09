package com.example.raising;

import com.google.gson.Gson;

import java.util.ArrayList;
import java.util.Date;

import lombok.Data;
import lombok.ToString;
import lombok.experimental.Accessors;

@Data
@Accessors(chain = true)
public class FileInfo {

    static Gson gson = new Gson();

    private String filename;
    private Date updateTime;
    private boolean isDirectory;
    private boolean isCompressFile;
    int length; //里面有多少文件
    private Long size;

    @Override
    public String toString() {
        return gson.toJson(this);
    }
}
