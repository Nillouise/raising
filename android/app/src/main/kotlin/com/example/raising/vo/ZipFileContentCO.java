package com.example.raising.vo;

import java.util.HashMap;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.With;
import lombok.experimental.Accessors;

@Data
@Accessors(chain = true)
@With
@AllArgsConstructor
@NoArgsConstructor
public class ZipFileContentCO {
    public String absFilename;
    public String zipAbsFilename; //压缩文件内的绝对路径
    public int index;
    public int length; //整个压缩文件内的文件的数量。
    public long wholeFileSize;
    public byte[] content;

    HashMap<String, Object> getMap() {
        HashMap<String, Object> res = new HashMap<>();
        res.put("absFilename", absFilename);
        res.put("zipAbsFilename", zipAbsFilename);
        res.put("index", index);
        res.put("length", length);
        res.put("content", content);
        res.put("wholeFileSize", wholeFileSize);
        return res;
    }

    public ZipFileContentCO copy() {
        ZipFileContentCO res = new ZipFileContentCO();
        res.absFilename = absFilename;
        res.zipAbsFilename = zipAbsFilename;
        res.index = index;
        res.length = length;
        res.content = content;
        res.wholeFileSize = wholeFileSize;
        return res;
    }

}
