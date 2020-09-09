package com.example.raising.vo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import lombok.Data;
import lombok.experimental.Accessors;

@Data
@Accessors(chain = true)
public class SmbResult implements GetMapInterface {
    String msg;
    Object result;

    public static SmbResult ofEmptyIndex() {
        return new SmbResult().setMsg("empty indexs");
    }

    public static SmbResult ofSuccessful() {
        return new SmbResult().setMsg("successful");
    }

    public static SmbResult ofCancel() {
        return new SmbResult().setMsg("cancel");
    }

    public static SmbResult ofContainNotExistIndex() {
        return new SmbResult().setMsg("contain not exist index");
    }

    public static SmbResult ofUnknownError() {
        return new SmbResult().setMsg("unknown error");
    }

    public SmbResult setDirectories(List<DirectoryVO> vos) {
        List<HashMap> res = new ArrayList<HashMap>();
        for (DirectoryVO vo : vos) {
            res.add(vo.getMap());
        }
        result = res;
        return this;
    }

    public SmbResult setFiles(List<FileVO> vos) {
        List<HashMap> res = new ArrayList<HashMap>();
        for (FileVO vo : vos) {
            res.add(vo.getMap());
        }
        result = res;
        return this;
    }


    @Override
    public HashMap<String, Object> getMap() {
        HashMap<String, Object> res = new HashMap<>();
        res.put("msg", msg);
        res.put("result", result);
        return res;
    }

}
