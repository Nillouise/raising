package com.example.raising;

import android.os.Handler;
import android.os.Looper;

import com.orhanobut.logger.Logger;

import net.sf.sevenzipjbinding.IInStream;
import net.sf.sevenzipjbinding.SevenZipException;

import org.apache.commons.lang3.exception.ExceptionUtils;

import java.io.IOException;
import java.util.HashMap;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

import io.flutter.plugin.common.MethodChannel;


/**
 * 这个回调使用了flutter的webdav，用了性能测试分析发现序列化的性能太低了，不能用在这么频繁调用的数据传输中，
 * 但代码不应该被删除，只是用{@link NativeWebDavRandomFile}代替了，之后改回来只需要小幅改动。
 * 当然，测试没那么严谨，可能也是别的问题导致的
 */
public class WebDavRandomFile implements IInStream {

    /**
     * 这里不再使用文件名作为标识，因为这是个短暂的存在，反之，由于总是flutter代码发起调用的，所以flutter代码能处理这个标识即可
     * 这样就可以使用连接池之类的技术。
     * 如果不是flutter发起的调用，比如是smb的调用，则不使用此类。
     */
    private String recallId;
    private volatile AtomicLong offset;
    private long fileLength;

    public WebDavRandomFile(String recallId, long offset, long fileLength) {
        this.recallId = recallId;
        this.offset = new AtomicLong(offset);
        this.fileLength = fileLength;
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
        return this.offset.longValue();
    }

    @Override
    public int read(byte[] data) throws SevenZipException {
        Logger.i("java begin reading" + data.length);

        HashMap<String, Object> map = new HashMap<>();
        map.put("recallId", this.recallId);
        map.put("begin", this.offset.longValue());
        map.put("end", this.offset.longValue() + data.length - 1);
        CountDownLatch countDownLatch = new CountDownLatch(1);
        AtomicInteger length = new AtomicInteger(0);

        try {
            new Handler(Looper.getMainLooper()).post(
                    new Runnable() {
                        @Override
                        public void run() {
                            MainActivity.Companion.getMethodChannel().invokeMethod("streamFile", map, new MethodChannel.Result() {
                                @Override
                                public void success(Object o) {
                                    Logger.d("call flutter successful" + String.valueOf(o));
                                    byte[] res = (byte[]) o;
                                    length.set(res.length);
                                    System.arraycopy(res, 0, data, 0, Math.min(res.length, data.length));
                                    countDownLatch.countDown();
                                }

                                @Override
                                public void error(String s, String s1, Object o) {
                                    Logger.e("call error" + s + s1 + String.valueOf(o));
                                    countDownLatch.countDown();
                                }

                                @Override
                                public void notImplemented() {
                                }
                            });

                        }
                    }

            );
            Logger.i("wait for countDownlatch");
            countDownLatch.await();
            this.offset.addAndGet(length.intValue());
            Logger.i("read + " + length.intValue() + "successful");
            return length.intValue();
//        } catch (InterruptedException e) {
//            throw new SevenZipException("countDownLatch Intterupted!");
        } catch (Exception e) {
            Logger.e("invokeMethod(\"testFoo" + ExceptionUtils.getStackTrace(e));
            throw new SevenZipException("get range error");
        }
//        Logger.i("buffer %d byte",data.length);
//        int read = file.read(data, offset);
//        Logger.i("read %d byte",read);
    }

    @Override
    public void close() throws IOException {
//        file.close();
    }
}
