package io.flutter.plugins;

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
    private Long size;
    private Date updateTime;

    private ArrayList<String> contentFiles;
    private Integer contentFilesLength;

    @Override
    public String toString() {
        return gson.toJson(this);
    }
}
