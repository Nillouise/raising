package io.flutter.plugins;

import com.hierynomus.msdtyp.AccessMask;
import com.hierynomus.msfscc.FileAttributes;
import com.hierynomus.msfscc.fileinformation.FileIdBothDirectoryInformation;
import com.hierynomus.msfscc.fileinformation.FileStandardInformation;
import com.hierynomus.mssmb2.SMB2CreateDisposition;
import com.hierynomus.mssmb2.SMB2CreateOptions;
import com.hierynomus.mssmb2.SMB2ShareAccess;
import com.hierynomus.mssmb2.SMBApiException;
import com.hierynomus.smbj.SMBClient;
import com.hierynomus.smbj.SmbConfig;
import com.hierynomus.smbj.auth.AuthenticationContext;
import com.hierynomus.smbj.connection.Connection;
import com.hierynomus.smbj.session.Session;
import com.hierynomus.smbj.share.DiskShare;
import com.hierynomus.smbj.share.File;
import com.orhanobut.logger.Logger;

import net.sf.sevenzipjbinding.ExtractOperationResult;
import net.sf.sevenzipjbinding.IInArchive;
import net.sf.sevenzipjbinding.ISequentialOutStream;
import net.sf.sevenzipjbinding.PropID;
import net.sf.sevenzipjbinding.SevenZip;
import net.sf.sevenzipjbinding.SevenZipException;
import net.sf.sevenzipjbinding.simple.ISimpleInArchive;
import net.sf.sevenzipjbinding.simple.ISimpleInArchiveItem;

import org.apache.commons.lang3.exception.ExceptionUtils;

import java.io.*;
import java.util.*;
import java.util.concurrent.Callable;
import java.util.concurrent.CancellationException;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import io.flutter.plugins.exception.SmbException;
import io.flutter.plugins.exception.SmbInterruptException;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.With;
import lombok.experimental.Accessors;

interface ProcessShare<T> {
    T process(DiskShare share) throws Exception;
}

public class Smb {
    private String hostname;
    private String shareName;
    private String domain;
    private String username;
    private String passwrod;
    private String path;
    private String searchPattern;

    @Override
    public String toString() {
        return "Smb{" +
                "hostname='" + hostname + '\'' +
                ", shareName='" + shareName + '\'' +
                ", domain='" + domain + '\'' +
                ", username='" + username + '\'' +
                ", passwrod='" + passwrod + '\'' +
                ", path='" + path + '\'' +
                ", searchPattern='" + searchPattern + '\'' +
                '}';
    }

    public Smb(String hostname, String shareName, String domain, String username, String passwrod, String path, String searchPattern) {
        this.hostname = hostname;
        this.shareName = shareName;
        this.domain = domain;
        this.username = username;
        this.passwrod = passwrod;
        this.path = path;
        this.searchPattern = searchPattern;
    }

    public Smb() {

    }

    void test() {
        SMBClient client = new SMBClient();
        System.out.println("begin java smb test");
        try (Connection connection = client.connect("109.131.14.238")) {

            System.out.println("to author");
            AuthenticationContext ac = new AuthenticationContext("jh.tan", "madness3###".toCharArray(), "CORP");
            Session session = connection.authenticate(ac);

            System.out.println("list session");
            // Connect to Share
            try (DiskShare share = (DiskShare) session.connectShare("flutter")) {
                System.out.println("list file");
                for (FileIdBothDirectoryInformation f : share.list("smbjar", "*")) {
                    System.out.println("File : " + f.getFileName());
                }
            } catch (Exception e) {
                System.out.println(ExceptionUtils.getStackTrace(e));
            }
        } catch (Exception e) {
            System.out.println(ExceptionUtils.getStackTrace(e));
        }
    }


    private SMBClient getClient() {
        SmbConfig config = SmbConfig.builder()
                .withTimeout(30, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
                .withSoTimeout(30, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
                .build();
        SMBClient client = new SMBClient(config);
        return client;
    }


    public ArrayList<FileInfo> listFiles(String path, String searchPattern) throws Exception {
        ArrayList<FileInfo> res = new ArrayList<FileInfo>();
        SMBClient client = getClient();

        System.out.println("curren smb setting" + this.toString());

        try (Connection connection = client.connect(hostname)) {
            AuthenticationContext ac;
            if (passwrod != null) {
                ac = new AuthenticationContext(username, passwrod.toCharArray(), domain);
            } else {
                ac = AuthenticationContext.anonymous();
            }
            Session session = connection.authenticate(ac);

            // Connect to Share
            try (DiskShare share = (DiskShare) session.connectShare(shareName)) {
                for (FileIdBothDirectoryInformation f : share.list(path, searchPattern)) {
                    FileInfo fi = new FileInfo().setFilename(f.getFileName())
                            .setSize(f.getEndOfFile()).setUpdateTime(f.getLastWriteTime().toDate());
                    res.add(fi);
                }
            } catch (Exception e) {
                throw e;
            }
            return res;
        } catch (Exception e) {
            throw e;
        }
    }

    public <T> T processShare(String hostname, String shareName, String domain, String username, String passwrod, String path, String searchPattern, ProcessShare<T> process) {
        SMBClient client = getClient();

        try (Connection connection = client.connect(hostname)) {
            AuthenticationContext ac;
            if (passwrod != null) {
                ac = new AuthenticationContext(username, passwrod.toCharArray(), domain);
            } else {
                ac = AuthenticationContext.guest();
            }
            Session session = connection.authenticate(ac);

            // Connect to Share
            try (DiskShare share = (DiskShare) session.connectShare(shareName)) {
                return process.process(share);
            } catch (Exception e) {
                Logger.e(ExceptionUtils.getStackTrace(e));
            }
        } catch (Exception e) {
            Logger.e(ExceptionUtils.getStackTrace(e));
        }
        return null;
    }

    public <T> T processShare(ProcessShare<T> process) throws Exception {
        SMBClient client = getClient();

        try (Connection connection = client.connect(hostname)) {
            AuthenticationContext ac;
            if (passwrod != null) {
                ac = new AuthenticationContext(username, passwrod.toCharArray(), domain);
            } else {
                ac = AuthenticationContext.guest();
            }
            Session session = connection.authenticate(ac);

            // Connect to Share
            try (DiskShare share = (DiskShare) session.connectShare(shareName)) {
                return process.process(share);
            } catch (Exception e) {
                throw e;
            }
        } catch (Exception e) {
            throw e;
        }
    }


    public ProcessShare<String> uploadFile(final String filename, final byte[] bytes) {
        return new ProcessShare<String>() {
            @Override
            public String process(DiskShare share) {
                // this is com.hierynomus.smbj.share.File !
                File f = null;
                int idx = filename.lastIndexOf("/");

                // if file is in folder(s), create them first
                if (idx > -1) {
                    String folder = filename.substring(0, idx);
                    try {
                        if (!share.folderExists(folder)) share.mkdir(folder);
                    } catch (SMBApiException ex) {
                        throw new RuntimeException(ex);
                    }

                }

                // I am creating file with flag FILE_CREATE, which will throw if file exists already
                boolean b = share.fileExists(filename);
                Logger.i("file statue {}", b);
//                if (!b) {
                f = share.openFile(filename,
                        new HashSet<>(Arrays.asList(AccessMask.GENERIC_ALL)),
                        new HashSet<>(Arrays.asList(FileAttributes.FILE_ATTRIBUTE_NORMAL)),
                        SMB2ShareAccess.ALL,
                        SMB2CreateDisposition.FILE_OVERWRITE,
                        new HashSet<>(Arrays.asList(SMB2CreateOptions.FILE_DIRECTORY_FILE))
                );
//                }

                if (f == null) return "null";
                try (OutputStream os = f.getOutputStream()) {
                    os.write(bytes);
                    os.flush();
                } catch (Exception e) {
                    Logger.e(ExceptionUtils.getStackTrace(e));
                }
                return "ok";
            }
        };
    }


    public byte[] getFile(final String filename, DiskShare share) throws SmbException {

        // this is com.hierynomus.smbj.share.File !
        File f = null;
        boolean fileExists = share.fileExists(filename);
        if (!fileExists) {
            Logger.w("File {} not exist.", filename);
            throw new SmbException("File not exist");
        }
        File smbFileRead = share.openFile(filename, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null);
        FileStandardInformation info = smbFileRead.getFileInformation(FileStandardInformation.class);
        long endOfFile = info.getEndOfFile();
        byte[] res = new byte[(int) endOfFile];
        InputStream in = smbFileRead.getInputStream();
        int len = 0;
        try {
            int total = 0;
            long begin = System.currentTimeMillis();
            long logCtroller = System.currentTimeMillis();
            while ((len = in.read(res, total, 4096)) != -1) {
                total += len;
                if (System.currentTimeMillis() > logCtroller + 5000) {
                    Logger.i("total {} m", total / 1024 / 1024);
                    logCtroller = System.currentTimeMillis();
                }
            }
            Logger.i("transferr {}m file cost {} ms", total / 1024 / 1024, System.currentTimeMillis() - begin);
            return res;
        } catch (Exception e) {
            Logger.e("{}", ExceptionUtils.getStackTrace(e));
            throw new SmbException("error when reading file");
        }
    }

    public static void listZip(final String filename, DiskShare share) throws SmbException {
        Logger.i("begin to list Zip 2");
        Logger.i("filename is" + filename);
        Logger.i("logger file name");
        // this is com.hierynomus.smbj.share.File !
        File f = null;
        boolean fileExists = share.fileExists(filename);
        if (!fileExists) {
            Logger.w("File {} not exist.", filename);
            throw new SmbException("File not exist");
        }
        File smbFileRead = share.openFile(filename, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null);
        FileStandardInformation info = smbFileRead.getFileInformation(FileStandardInformation.class);
        long endOfFile = info.getEndOfFile();
        InputStream in = smbFileRead.getInputStream();

        RandomAccessFile randomAccessFile = null;
        IInArchive inArchive = null;
        try {
            inArchive = SevenZip.openInArchive(null, // autodetect archive type
                    new SmbRandomFile(smbFileRead));

            System.out.println("   Size   | Compr.Sz. | Filename");
            System.out.println("----------+-----------+---------");
            int itemCount = inArchive.getNumberOfItems();
            for (int i = 0; i < itemCount; i++) {
                System.out.println(String.format("%9s | %9s | %s", //
                        inArchive.getProperty(i, PropID.SIZE),
                        inArchive.getProperty(i, PropID.PACKED_SIZE),
                        inArchive.getProperty(i, PropID.PATH)));
            }
        } catch (Exception e) {
            Logger.e(ExceptionUtils.getStackTrace(e));
        }
    }

    public String listContent(final String filename, DiskShare share) throws Exception {
        // this is com.hierynomus.smbj.share.File !
        File f = null;
        boolean fileExists = share.fileExists(filename);
        if (!fileExists) {
            throw new SmbException(String.format("File %s not exist", filename));
        }
        File smbFileRead = share.openFile(filename,
                EnumSet.of(AccessMask.GENERIC_READ),
                null,
                Collections.singleton(SMB2ShareAccess.FILE_SHARE_READ), SMB2CreateDisposition.FILE_OPEN, null);
        FileStandardInformation info = smbFileRead.getFileInformation(FileStandardInformation.class);
        long endOfFile = info.getEndOfFile();
        InputStream in = smbFileRead.getInputStream();

        RandomAccessFile randomAccessFile = null;
        IInArchive inArchive = null;
        try {
            inArchive = SevenZip.openInArchive(null, // autodetect archive type
                    new SmbRandomFile(smbFileRead));

//            System.out.println("   Size   | Compr.Sz. | Filename");
//            System.out.println("----------+-----------+---------");
            int itemCount = inArchive.getNumberOfItems();
//            for (int i = 0; i < itemCount; i++) {
//                System.out.println(String.format("%9s | %9s | %s", //
//                        inArchive.getProperty(i, PropID.SIZE),
//                        inArchive.getProperty(i, PropID.PACKED_SIZE),
//                        inArchive.getProperty(i, PropID.PATH)));
//            }
            return new FileInfo().setFilename(smbFileRead.getFileName()).setLength(itemCount).toString();
        } catch (Exception e) {
            throw e;
        }
    }

    @Data
    @AllArgsConstructor
    @Accessors(chain = true)
    static
    class ZipTask {
        String filename;
        List<Integer> indexs;
    }

    @Data
    @Accessors(chain = true)
    @With
    @AllArgsConstructor
    @NoArgsConstructor
    static
    class ZipFileContent {
        String filename;
        String zipFilename;
        Integer index;
        Integer length;
        byte[] content;

        HashMap<String, Object> getMap() {
            HashMap<String, Object> res = new HashMap<>();
            res.put("filename", filename);
            res.put("zipFilename", zipFilename);
            res.put("index", index);
            res.put("content", content);
            res.put("length", length);
            return res;
        }

        @Override
        public Object clone() throws CloneNotSupportedException {
            return super.clone();
        }
    }

    @Data
    @Accessors(chain = true)
    static
    class SmbHalfResult {
        String msg;
        HashMap<Integer, ZipFileContent> result;

        public static SmbHalfResult ofEmptyIndex() {
            return new SmbHalfResult().setMsg("empty indexs");
        }

        public static SmbHalfResult ofSuccessful() {
            return new SmbHalfResult().setMsg("successful");
        }

        public static SmbHalfResult ofCancel() {
            return new SmbHalfResult().setMsg("cancel");
        }

        public static SmbHalfResult ofContainNotExistIndex() {
            return new SmbHalfResult().setMsg("contain not exist index");
        }

        public static SmbHalfResult ofUnknownError() {
            return new SmbHalfResult().setMsg("unknown error");
        }

        HashMap getMap() {
            HashMap<String, Object> res = new HashMap<>();
            res.put("msg", msg);
            HashMap<Integer, HashMap<String, Object>> cvt = new HashMap<>();
            for (Map.Entry<Integer, ZipFileContent> entry : result.entrySet()) {
                cvt.put(entry.getKey(), entry.getValue().getMap());
            }
            res.put("result", cvt);
            return res;
        }
    }


    /**
     * 需求：子任务必须要原子化，batch要在这些子任务中实现，能够中断文件传输，最好也能返回batch中已完成的任务
     * 返回batch中已完成的任务：所以异常处理不能用throw，要存中间结果跟错误码，
     * 原子化：但由于顺序访问应该更快，所以同一个smb连接还是要处理同一个压缩文件下的子文件。
     * 中断文件传输，就需要shutdown 线程池，处理好中断信号Thread.currentThread().isInterrupted()
     */
    private ConcurrentHashMap<String, ConcurrentSkipListSet<Integer>> fileIndexTask = new ConcurrentHashMap<String, ConcurrentSkipListSet<Integer>>();
    private ExecutorService executorService = Executors.newFixedThreadPool(3);

    private ZipFileContent extractItem(ISimpleInArchiveItem item, int[] hash, ZipFileContent proto) throws SevenZipException, SmbException {
        ExtractOperationResult result;
        final long[] sizeArray = new long[1];
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        result = item.extractSlow(new ISequentialOutStream() {
            public int write(byte[] data) throws SevenZipException {
                //处理线程中断，这里不处理中断，因为一个文件传输很快
//                if (Thread.currentThread().isInterrupted()) {
//                    throw new SmbInterruptException("thread interrupt");
//                }
                hash[0] ^= Arrays.hashCode(data); // Consume data
                sizeArray[0] += data.length;
                try {
                    outputStream.write(data);
                } catch (IOException e) {
                    Logger.e(ExceptionUtils.getStackTrace(e));
                }
                return data.length; // Return amount of consumed data
            }
        });
        if (result == ExtractOperationResult.OK) {
            System.out.println(String.format("%9X | %10s | %s",
                    hash[0], sizeArray[0], item.getPath()));
            return proto.withZipFilename(item.getPath()).withContent(outputStream.toByteArray());
        } else {
            Logger.e("Error extracting item: " + result);
            throw new SmbException("extract eror" + result.toString());
        }
    }

    private String getAbsFilename(String filename) {
        return (path == null ? "" : path) + filename;
    }

    //由于中断的存在，本函数不一定能返回全部图片
    private SmbHalfResult getFileWorker(String filename, Boolean needFileDetailInfo, DiskShare share) throws Exception {
        HashMap<Integer, ZipFileContent> res = new HashMap<Integer, ZipFileContent>();
        ConcurrentSkipListSet<Integer> indexlst = fileIndexTask.get(filename);
        if (indexlst == null || indexlst.isEmpty()) {
            return SmbHalfResult.ofEmptyIndex().setResult(res);
        }
        String absFilename = getAbsFilename(filename);

        Logger.i("previewFileQueue file name %s", absFilename);
        File f = null;
        boolean fileExists = share.fileExists(absFilename);
        if (!fileExists) {
            Logger.w("File %s not exist.", absFilename);
            throw new SmbException("File " + absFilename + "not exist");
        }
        File smbFileRead = share.openFile(absFilename, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null);
        FileStandardInformation info = smbFileRead.getFileInformation(FileStandardInformation.class);

        InputStream in = smbFileRead.getInputStream();

        RandomAccessFile randomAccessFile = null;
        IInArchive inArchive = null;

        try {
            inArchive = SevenZip.openInArchive(null, // autodetect archive type
                    new SmbRandomFile(smbFileRead));

            // Getting simple interface of the archive inArchive
            ISimpleInArchive simpleInArchive = inArchive.getSimpleInterface();

//          System.out.println("   Hash   |    Size    | Filename");
//          System.out.println("----------+------------+---------");

            int curindex = 0;
            ZipFileContent proto = new ZipFileContent();
            if (Boolean.TRUE.equals(needFileDetailInfo)) {
                proto.setLength(simpleInArchive.getArchiveItems().length);
                proto.setFilename(filename);
            }

            for (ISimpleInArchiveItem item : simpleInArchive.getArchiveItems()) {
                final int[] hash = new int[]{0};
                if (!item.isFolder()) {
                    if (indexlst.contains(curindex)) {
                        indexlst.remove(curindex);
                        ZipFileContent zipFileContent =
                                extractItem(item, hash, proto).setIndex(curindex);
                        res.put(curindex, zipFileContent);
                    }
                    curindex++;
                }
                if (indexlst.isEmpty()) {
                    return SmbHalfResult.ofSuccessful().setResult(res);
                } else if (Thread.currentThread().isInterrupted()) {
                    //处理线程中断
                    return SmbHalfResult.ofCancel().setResult(res);
                }
            }
            Logger.i("curindex %s %s", curindex, indexlst);
            return SmbHalfResult.ofContainNotExistIndex().setResult(res);
        } catch (SmbInterruptException e) {
            Logger.e("Error closing file: " + ExceptionUtils.getStackTrace(e));
            return SmbHalfResult.ofCancel().setResult(res);
        } catch (Exception e) {
            Logger.e("Error closing file: " + e);
            return SmbHalfResult.ofUnknownError().setResult(res);
        } finally {
            if (inArchive != null) {
                try {
                    inArchive.close();
                } catch (SevenZipException e) {
                    Logger.e("Error closing archive: " + e);
                }
            }
            if (randomAccessFile != null) {
                try {
                    randomAccessFile.close();
                } catch (IOException e) {
                    Logger.e("Error closing file: " + e);
                }
            }
        }
    }

    public SmbHalfResult loadImageFromIndex(final String filename, ArrayList<Integer> indexs, Boolean needFileDetailInfo, DiskShare share) throws SmbException {
        fileIndexTask.put(filename, new ConcurrentSkipListSet<Integer>(indexs));
        Future<SmbHalfResult> task = executorService.submit(new Callable<SmbHalfResult>() {
            @Override
            public SmbHalfResult call() throws Exception {
                return getFileWorker(filename, needFileDetailInfo, share);
            }
        });

        try {
            return task.get();
        } catch (CancellationException e) {
            Logger.e(e, "%s %s %s", filename, String.valueOf(indexs));
            try {
                //睡眠一小段时间，是为了传输完成正在传输中的图片
                Thread.sleep(130);
                return task.get();
            } catch (Exception ex) {
                Logger.e(e, "double %s %s %s", filename, String.valueOf(indexs));
                return SmbHalfResult.ofCancel();
            }
        } catch (Exception e) {
            Logger.e(e, "%s %s %s", filename, String.valueOf(indexs));
            return SmbHalfResult.ofUnknownError();
        }
    }

    public void stopRequest() {
        fileIndexTask.clear();
        List<Runnable> runnables = executorService.shutdownNow();
    }

}