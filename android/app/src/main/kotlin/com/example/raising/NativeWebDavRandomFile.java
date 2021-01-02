package com.example.raising;

import android.os.Handler;
import android.os.Looper;


import com.orhanobut.logger.Logger;
import com.thegrizzlylabs.sardineandroid.Sardine;
import com.thegrizzlylabs.sardineandroid.impl.OkHttpSardine;

import net.sf.sevenzipjbinding.IInStream;
import net.sf.sevenzipjbinding.SevenZipException;

import org.apache.commons.lang3.exception.ExceptionUtils;

import java.io.IOException;
import java.io.InputStream;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;


import io.flutter.plugin.common.MethodChannel;

public class NativeWebDavRandomFile implements IInStream {
    /**
     * 这里不再使用文件名作为标识，因为这是个短暂的存在，反之，由于总是flutter代码发起调用的，所以flutter代码能处理这个标识即可
     * 这样就可以使用连接池之类的技术。
     * 如果不是flutter发起的调用，比如是smb的调用，则不使用此类。
     */
    private String recallId;
    private volatile AtomicLong offset;
    private long fileLength;
    private Sardine sardine;

    public NativeWebDavRandomFile(String recallId, long offset, long fileLength) {
        this.recallId = recallId;
        this.offset = new AtomicLong(offset);
        this.fileLength = fileLength;
        sardine = new OkHttpSardine();
        System.out.println("nativeWebDav Randfile init successful" + recallId + offset + "" + fileLength);
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
                throw new RuntimeException("Seek: unknown origin: " + seekOrigin);
        }
        System.out.println("NativeWebDavRandomFile seek " + offset + " " + seekOrigin);
        return this.offset.longValue();
    }

    @Override
    public int read(byte[] data) throws SevenZipException {
        HashMap<String, String> headers = new HashMap<>();
        headers.put("Range", "bytes=" + this.offset.longValue() + "-" + (this.offset.longValue() + data.length - 1));
        try {
            InputStream inputStream = sardine.get("http://192.168.1.111:9016/" + this.recallId, headers);
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
            System.out.println("NativeWebDavRandomFIle read " + headers + " " + co);
            this.offset.addAndGet(co);
            return co;
        } catch (IOException e) {
            System.out.println(e);
            throw new SevenZipException("io error", e);
        }
    }

    @Override
    public void close() throws IOException {
//        file.close();
    }
}
