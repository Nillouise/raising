package com.example.raising;

import com.orhanobut.logger.Logger;
import com.thegrizzlylabs.sardineandroid.Sardine;
import com.thegrizzlylabs.sardineandroid.impl.OkHttpSardine;

import net.sf.sevenzipjbinding.IInStream;
import net.sf.sevenzipjbinding.SevenZipException;


import org.apache.commons.lang3.exception.ExceptionUtils;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

public class NativeWebDavRandomFile implements IInStream {

    private String absPathLink;//这里的basPath包含了整个url，但其他的协议的类其实要包含hostname吗，这其实会对
    private String username;
    private String password;
    private volatile AtomicLong offset;
    private long fileLength;
    private static volatile ConcurrentHashMap<String, Sardine> sardines = new ConcurrentHashMap<>();

    private static Sardine getSarding(String absPath, String user, String password) {
        String key = absPath + user + password;
        if (sardines.get(key) == null) {
            synchronized (NativeWebDavRandomFile.class) {
                if (sardines.get(key) == null) {
                    Sardine s = new OkHttpSardine();
                    s.setCredentials(user, password);
                    sardines.put(key, s);
                }
            }
        }
        return sardines.get(key);
    }


    public NativeWebDavRandomFile(String absPathLink, String username, String password, long offset, long fileLength) {
        this.absPathLink = absPathLink;
        this.offset = new AtomicLong(offset);
        this.fileLength = fileLength;
        this.username = username;
        this.password = password;
    }

    @Override
    public long seek(long offset, int seekOrigin) throws SevenZipException {
        switch (seekOrigin) {
            case SEEK_SET:
                this.offset.set(offset);
                break;

            case SEEK_CUR:
                this.offset.addAndGet(offset);
                break;

            case SEEK_END:
                this.offset.set(fileLength + offset);
                break;

            default:
                throw new SevenZipException("Seek: unknown origin: " + seekOrigin);
        }
        return this.offset.longValue();
    }

    @Override
    public int read(byte[] data) throws SevenZipException {
        HashMap<String, String> headers = new HashMap<>();
        headers.put("Range", "bytes=" + this.offset.longValue() + "-" + (this.offset.longValue() + data.length - 1));
        try {
            InputStream inputStream = getSarding(absPathLink, username, password).get(this.absPathLink, headers);
            int co = 0;
            for (; ; ) {
                int cr = inputStream.read(data, co, data.length - co);
                if (cr == 0 || cr == -1) {
                    break;
                }
                co += cr;
                if (co == data.length) {
                    break;
                }
            }
            inputStream.close();
            this.offset.addAndGet(co);
            return co;
        } catch (Exception e) {
            Logger.e("read webdav error" + this.absPathLink + " " + headers + " " + ExceptionUtils.getStackTrace(e));
            throw new SevenZipException("read webdav error", e);
        }
    }

    @Override
    public void close() throws IOException {
//        file.close();
    }
}
