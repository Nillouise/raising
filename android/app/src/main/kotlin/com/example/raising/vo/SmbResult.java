package com.example.raising.vo;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;




public class SmbResult implements GetMapInterface {
    String msg;
    Object result;

    public String getMsg() {
        return msg;
    }

    public SmbResult setMsg(String msg) {
        this.msg = msg;
        return this;
    }

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

    public SmbResult setZipFiles(HashMap<Integer, ZipFileContentCO> vos) {
        HashMap<Integer, HashMap> res = new HashMap<Integer, HashMap>();
        for (Map.Entry<Integer, ZipFileContentCO> e : vos.entrySet()) {
            res.put( e.getKey(),e.getValue().getMap());
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
