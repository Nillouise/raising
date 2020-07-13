package io.flutter.plugins;

import com.hierynomus.msdtyp.AccessMask;
import com.hierynomus.msfscc.FileAttributes;
import com.hierynomus.msfscc.fileinformation.FileIdBothDirectoryInformation;
import com.hierynomus.msfscc.fileinformation.FileStandardInformation;
import com.hierynomus.mssmb2.SMB2CreateDisposition;
import com.hierynomus.mssmb2.SMB2CreateOptions;
import com.hierynomus.mssmb2.SMB2ShareAccess;
import com.hierynomus.mssmb2.SMBApiException;
import com.hierynomus.protocol.commons.EnumWithValue;
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
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import io.flutter.plugins.exception.SmbException;
import io.flutter.plugins.exception.SmbInterruptException;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.With;
import lombok.experimental.Accessors;

import static com.hierynomus.msfscc.FileAttributes.FILE_ATTRIBUTE_DIRECTORY;


interface ProcessShare<T> {
    T process(DiskShare share) throws Exception;
}

public class Smb {

    private static final String TAG = "Smb";

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


    public ArrayList<FileInfo> listFiles(String path, String searchPattern,String shareName) throws Exception {
        ArrayList<FileInfo> res = new ArrayList<FileInfo>();
        SMBClient client = getClient();

        Logger.d("listFiles: curren smb setting %s", this.toString());
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
                    FileInfo fi = new FileInfo()
                            .setFilename(f.getFileName())
                            .setSize(f.getEndOfFile())
                            .setUpdateTime(f.getLastWriteTime().toDate())
                            .setDirectory(EnumWithValue.EnumUtils.isSet(f.getFileAttributes(), FILE_ATTRIBUTE_DIRECTORY));
                    res.add(fi);
                }
            } catch (Exception e) {
                Logger.e(e, "path %s searchPattern %s", path, searchPattern);
                throw e;
            }
            return res;
        } catch (Exception e) {
            Logger.e(e, "path %s searchPattern %s", path, searchPattern);
            throw e;
        }
    }

    @Deprecated
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

    public <T> T processShare(ProcessShare<T> process,String shareName) throws Exception {
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


    @Deprecated
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


    @Deprecated
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

    @Deprecated
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

    @Deprecated
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
        String absFilename;
        String zipFilename;
        Integer index;
        Integer length;
        byte[] content;
        boolean isCompressFile = true;

        HashMap<String, Object> getMap() {
            HashMap<String, Object> res = new HashMap<>();
            res.put("absFilename", absFilename);
            res.put("zipFilename", zipFilename);
            res.put("index", index);
            res.put("content", content);
            res.put("length", length);
            res.put("isCompressFile", isCompressFile);
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
        HashMap<String, ZipFileContent> result;

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
            HashMap<String, HashMap<String, Object>> cvt = new HashMap<>();
            if (result != null) {
                for (Map.Entry<String, ZipFileContent> entry : result.entrySet()) {
                    cvt.put(String.valueOf(entry.getKey()), entry.getValue().getMap());
                }
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

    private final int interrupttime = 100;

    private ZipFileContent extractItem(ISimpleInArchiveItem item, int[] hash, ZipFileContent proto) throws SevenZipException, SmbException {
        long begin = System.currentTimeMillis();
        ExtractOperationResult result;
        final long[] sizeArray = new long[1];
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        result = item.extractSlow(new ISequentialOutStream() {
            public int write(byte[] data) throws SevenZipException {
//                处理线程中断，这里不会马上处理中断，因为假设一个文件传输很快
                if (Thread.currentThread().isInterrupted() && System.currentTimeMillis() - begin > interrupttime) {
                    throw new SmbInterruptException("thread interrupt");
                }

                hash[0] ^= Arrays.hashCode(data); // Consume data
                sizeArray[0] += data.length;
                try {
                    outputStream.write(data);
                } catch (IOException e) {
                    Logger.e(e, "extractItem error");
                }
                return data.length; // Return amount of consumed data
            }
        });
        if (result == ExtractOperationResult.OK) {
            Logger.i("extreactItem path %s size %d use %d ms.", item.getPath(), sizeArray[0], System.currentTimeMillis() - begin);
            return proto.withZipFilename(item.getPath()).withContent(outputStream.toByteArray());
        } else {
            Logger.e("Error extracting item: " + result);
            throw new SmbException("Error extracting item:" + result.toString());
        }
    }


    //由于中断的存在，本函数不一定能返回全部图片
    private SmbHalfResult getFileWorker(String absFilename, Boolean needFileDetailInfo, List<Integer> indexs, DiskShare share) throws Exception {
        HashMap<String, ZipFileContent> res = new HashMap<String, ZipFileContent>();
//        ConcurrentSkipListSet<Integer> indexlst = fileIndexTask.get(absFilename);
        Set<Integer> indexlst = new HashSet<>(indexs);
        if (indexlst == null || indexlst.isEmpty()) {
            return SmbHalfResult.ofEmptyIndex().setResult(res);
        }

        Logger.i("previewFileQueue file name %s", absFilename);
        File f = null;
        boolean fileExists = share.fileExists(absFilename);
        if (!fileExists) {
            Logger.w("File %s not exist.", absFilename);
            throw new SmbException("File " + absFilename + " not exist");
        }
        File smbFileRead = share.openFile(absFilename, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null);
        FileStandardInformation info = smbFileRead.getFileInformation(FileStandardInformation.class);

        InputStream in = smbFileRead.getInputStream();

        RandomAccessFile randomAccessFile = null;
        IInArchive inArchive = null;

        try {
            inArchive = SevenZip.openInArchive(null, // autodetect archive type
                    new SmbRandomFile(smbFileRead));

            ISimpleInArchive simpleInArchive = inArchive.getSimpleInterface();

            ZipFileContent proto = new ZipFileContent();
            proto.setLength(simpleInArchive.getArchiveItems().length);
            proto.setAbsFilename(absFilename);

            ArrayList<String> paths = new ArrayList<>();
            HashMap<String, Integer> mapPath = new HashMap<>();
            int archiIndex = 0;
            long getAchiveItemTime = System.currentTimeMillis();
            for (ISimpleInArchiveItem item : simpleInArchive.getArchiveItems()) {
                if (!item.isFolder()) {
                    paths.add(item.getPath());
                    mapPath.put(item.getPath(), archiIndex++);
                }
            }
            Logger.d("iterate archiveItems name use %d ms", System.currentTimeMillis() - getAchiveItemTime);
            paths.sort(String::compareTo);

            for (Integer integer : indexlst) {
                final int[] hash = new int[]{0};
                if (Thread.currentThread().isInterrupted()) {
                    return SmbHalfResult.ofCancel().setResult(res);
                } else if (integer >= 0 && integer < paths.size()) {
                    res.put(String.valueOf(integer), extractItem(simpleInArchive.getArchiveItem(mapPath.get(paths.get(integer))), hash, proto).setIndex(integer));
                } else {
                    Logger.d("SmbHalfResult.ofContainNotExistIndex page %d ", integer);
                    return SmbHalfResult.ofContainNotExistIndex().setResult(res);
                }
            }
            return SmbHalfResult.ofSuccessful().setResult(res);


//            for (ISimpleInArchiveItem item : simpleInArchive.getArchiveItems()) {
//                Logger.d("iterate path %s %s", curindex, item.getPath());
//                final int[] hash = new int[]{0};
//                if (!item.isFolder()) {
//                    if (indexlst.contains(curindex)) {
//                        indexlst.remove(curindex);
//                        ZipFileContent zipFileContent =
//                                extractItem(item, hash, proto).setIndex(curindex);
//                        res.put(String.valueOf(curindex), zipFileContent);
//                    }
//                    curindex++;
//                }
//                if (indexlst.isEmpty()) {
//                    return SmbHalfResult.ofSuccessful().setResult(res);
//                } else if (Thread.currentThread().isInterrupted()) {
//                    //处理线程中断
//                    return SmbHalfResult.ofCancel().setResult(res);
//                }
//            }
//            Logger.i("curindex %s %s", curindex, indexlst);
//            return SmbHalfResult.ofContainNotExistIndex().setResult(res);
        } catch (SmbInterruptException e) {
            Logger.e("Error closing file: " + ExceptionUtils.getStackTrace(e));
            return SmbHalfResult.ofCancel().setResult(res);
        } catch (Exception e) {
            Logger.e(e, absFilename);
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

    public SmbHalfResult loadImageFromIndex(final String absFilename, ArrayList<Integer> indexs, Boolean needFileDetailInfo, DiskShare share) throws SmbException {
//        fileIndexTask.put(absFilename, new ConcurrentSkipListSet<Integer>(indexs));
        Future<SmbHalfResult> task = executorService.submit(new Callable<SmbHalfResult>() {
            @Override
            public SmbHalfResult call() throws Exception {
                return getFileWorker(absFilename, needFileDetailInfo, indexs, share);
            }

        });

        try {
            return task.get();
        } catch (CancellationException e) {
            Logger.e(e, "%s %s", absFilename, String.valueOf(indexs));
            try {
                //睡眠一小段时间，是为了传输完成正在传输中的图片
                Thread.sleep(130);
                return task.get();
            } catch (Exception ex) {
                Logger.e(e, "double %s %s", absFilename, String.valueOf(indexs));
                return SmbHalfResult.ofCancel();
            }
        } catch (Exception e) {
            Logger.e(e, "%s %s", absFilename, String.valueOf(indexs));
            return SmbHalfResult.ofUnknownError();
        }
    }


    public SmbHalfResult loadImageFile(final String absFilename, DiskShare share) throws SmbException {
        Future<SmbHalfResult> task = executorService.submit(new Callable<SmbHalfResult>() {
            @Override
            public SmbHalfResult call() throws Exception {
                File f = null;
                boolean fileExists = share.fileExists(absFilename);
                if (!fileExists) {
                    Logger.w("File %s not exist.", absFilename);
                    throw new SmbException("File " + absFilename + " not exist");
                }
                try {
                    File smbFileRead = share.openFile(absFilename, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null);
                    FileStandardInformation info = smbFileRead.getFileInformation(FileStandardInformation.class);
                    InputStream in = smbFileRead.getInputStream();
                    ByteArrayOutputStream buffer = new ByteArrayOutputStream();
                    int nRead;
                    byte[] data = new byte[16384];
                    int total = 0;
                    while ((nRead = in.read(data, 0, data.length)) != -1) {
                        buffer.write(data, 0, nRead);
                        total += nRead;
                    }
                    byte[] imagebyte = buffer.toByteArray();
                    HashMap<String, ZipFileContent> res = new HashMap<>();
                    res.put("0", new ZipFileContent().setAbsFilename(absFilename).setCompressFile(false).setContent(imagebyte).setIndex(0).setLength(total));
                    return SmbHalfResult.ofSuccessful().setResult(res);
                } catch (Exception e) {
                    Logger.e(e, "cannot load image file");
                    throw new SmbException(e.getMessage());
                }
            }
        });

        try {
            return task.get();
        } catch (CancellationException e) {
            Logger.e(e, "%s", absFilename);
            try {
                //睡眠一小段时间，是为了传输完成正在传输中的图片
                Thread.sleep(130);
                return task.get();
            } catch (Exception ex) {
                Logger.e(e, "double %s", absFilename);
                return SmbHalfResult.ofCancel();
            }
        } catch (Exception e) {
            Logger.e(e, "%s", absFilename);
            return SmbHalfResult.ofUnknownError();
        }
    }

    public void stopSmbRequest() {
        fileIndexTask.clear();
        List<Runnable> runnables = executorService.shutdownNow();
    }

}