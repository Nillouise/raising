package io.flutter.plugins;

import com.hierynomus.msfscc.fileinformation.FileStandardInformation;
import com.hierynomus.smbj.share.File;
import com.orhanobut.logger.Logger;

import net.sf.sevenzipjbinding.IInStream;
import net.sf.sevenzipjbinding.SevenZipException;
import net.sf.sevenzipjbinding.impl.RandomAccessFileInStream;

import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.RandomAccessFile;

public class SmbRandomFile implements IInStream {
    File file;
    volatile long offset;
    long fileLength;
    GeneratedPluginRegistrant t;

    public SmbRandomFile(File file) {
        this.file = file;
        FileStandardInformation info = file.getFileInformation(FileStandardInformation.class);
        fileLength = info.getEndOfFile();
    }

    @Override
    public long seek(long offset, int seekOrigin) throws SevenZipException {

        switch (seekOrigin) {
            case SEEK_SET:
                this.offset = offset;
                break;

            case SEEK_CUR:
                this.offset += offset;
                break;

            case SEEK_END:
                this.offset = fileLength + offset;
                break;

            default:
                throw new RuntimeException("Seek: unknown origin: " + seekOrigin);
        }

        return this.offset;
    }

    @Override
    public int read(byte[] data) throws SevenZipException {
//        Logger.i("buffer %d byte",data.length);
        int read = file.read(data, offset);
//        Logger.i("read %d byte",read);
        offset += read;
        return read;
    }

    @Override
    public void close() throws IOException {
        file.close();
    }
}
