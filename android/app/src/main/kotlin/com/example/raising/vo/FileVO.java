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
public class FileVO implements GetMapInterface {
    String filename;
    String absFilename;//由于有可能能获得更详细的绝对路径，不一定跟查询的绝对路径一样，目前可能直接设为空
    String absZipFilename;//
    Integer index;
    Integer size;
    byte[] content;
    boolean isCompressFile = true;

    @Override
    public HashMap<String, Object> getMap() {
        HashMap<String, Object> res = new HashMap<>();
        if (filename != null) {
            res.put("filename", filename);
        }
        if (absFilename != null) {
            res.put("absFilename", absFilename);
        }
        if (absZipFilename != null) {
            res.put("absZipFilename", absZipFilename);
        }
        if (index != null) {
            res.put("index", index);
        }
        if (size != null) {
            res.put("size", size);
        }
        if (content != null) {
            res.put("content", content);
        }
        res.put("isCompressFile", isCompressFile);
        return res;
    }

}
