package com.example.raising.vo;

import java.lang.reflect.Array;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

public class SmbCO {
    private String hostname; //combine with path
    private String domain;
    private String username;
    private String password;
    private String wholePath;

    public String getHostname() {
        return hostname;
    }

    public void setHostname(String hostname) {
        this.hostname = hostname;
    }

    public String getDomain() {
        return domain;
    }

    public void setDomain(String domain) {
        this.domain = domain;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getWholePath() {
        return wholePath;
    }

    public void setWholePath(String wholePath) {
        this.wholePath = wholePath;
    }


    public String getShareName() {
        if (wholePath == null) {
            return "";
        }
        String[] split = wholePath.split("[/\\\\\\\\]");
        if (split.length == 0) {
            return "";
        }
        return split[0];
    }

    public String getPath() {
        List<String> split = Arrays.asList(wholePath.split("[/\\\\\\\\]"));
        return String.join("/", split.subList(1, split.size()));
    }

    @Override
    public String toString() {
        return "SmbCO{" +
                "hostname=\'" + hostname + \'\\\'\' +
                ", domain=\'" + domain + \'\\\'\' +
                ", username=\'" + username + \'\\\'\' +
                ", password=\'" + password + \'\\\'\' +
                ", wholePath=\'" + wholePath + \'\\\'\' +
                '}';
    }

    public static SmbCO fromMap(HashMap map) {
        SmbCO smbCO = new SmbCO();
        smbCO.setHostname((String) map.get("hostname"));
        smbCO.setDomain((String) map.get("domain"));
        smbCO.setUsername((String) map.get("username"));
        smbCO.setPassword((String) map.get("password"));
        smbCO.setWholePath((String) map.get("wholePath"));
        return smbCO;
    }
}
