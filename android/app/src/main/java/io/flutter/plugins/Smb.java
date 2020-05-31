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
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import io.flutter.plugins.exception.SmbException;

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

    private SMBClient getClient() {
        SmbConfig config = SmbConfig.builder()
                .withTimeout(30, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
                .withSoTimeout(30, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
                .build();
        SMBClient client = new SMBClient(config);
        return client;
    }


    public ArrayList<String> listFiles(String path, String searchPattern) throws Exception {
        ArrayList<String> res = new ArrayList<String>();
        SMBClient client = getClient();

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
                    res.add(fi.toString());
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
            return new FileInfo().setFilename(smbFileRead.getFileName()).setContentFilesLength(itemCount).toString();
        } catch (Exception e) {
            throw e;
        }
    }

    private ConcurrentLinkedQueue<String> previewFileQueue = new ConcurrentLinkedQueue<>();
    private ExecutorService executorService = Executors.newFixedThreadPool(3);

    private HashMap<String, byte[]> getPreviewFileWorker(DiskShare share) throws Exception {
        HashMap<String, byte[]> res = new HashMap<String, byte[]>();
        while (true) {
            String filename = previewFileQueue.poll();
            if (filename == null) {
                return res;
            }
            Logger.i("previewFileQueue file name %s", filename);
            File f = null;
            boolean fileExists = share.fileExists(filename);
            if (!fileExists) {
                Logger.w("File %s not exist.", filename);
                throw new SmbException("File " + filename + "not exist");
            }
            File smbFileRead = share.openFile(filename, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null);
            FileStandardInformation info = smbFileRead.getFileInformation(FileStandardInformation.class);

            InputStream in = smbFileRead.getInputStream();

            RandomAccessFile randomAccessFile = null;
            IInArchive inArchive = null;

            try {
                inArchive = SevenZip.openInArchive(null, // autodetect archive type
                        new SmbRandomFile(smbFileRead));

                // Getting simple interface of the archive inArchive
                ISimpleInArchive simpleInArchive = inArchive.getSimpleInterface();

                System.out.println("   Hash   |    Size    | Filename");
                System.out.println("----------+------------+---------");

                for (ISimpleInArchiveItem item : simpleInArchive.getArchiveItems()) {
                    final int[] hash = new int[]{0};
                    if (!item.isFolder()) {
                        ExtractOperationResult result;

                        final long[] sizeArray = new long[1];

                        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
                        result = item.extractSlow(new ISequentialOutStream() {
                            public int write(byte[] data) throws SevenZipException {
                                hash[0] ^= Arrays.hashCode(data); // Consume data
                                sizeArray[0] += data.length;
//                                    res.put(filename, data);
                                try {
                                    outputStream.write(data);
                                } catch (IOException e) {
                                    e.printStackTrace();
                                }
                                return data.length; // Return amount of consumed data
                            }
                        });
                        res.put(filename, outputStream.toByteArray());
                        if (result == ExtractOperationResult.OK) {
                            System.out.println(String.format("%9X | %10s | %s",
                                    hash[0], sizeArray[0], item.getPath()));
                        } else {
                            System.err.println("Error extracting item: " + result);
                        }
                        break;
                    }
                }
            } catch (Exception e) {
                throw e;
            } finally {
                if (inArchive != null) {
                    try {
                        inArchive.close();
                    } catch (SevenZipException e) {
                        System.err.println("Error closing archive: " + e);
                    }
                }
                if (randomAccessFile != null) {
                    try {
                        randomAccessFile.close();
                    } catch (IOException e) {
                        System.err.println("Error closing file: " + e);
                    }
                }
            }

        }
    }

    public HashMap<String, byte[]> previewFile(final List<String> absFilenames, DiskShare share) throws SmbException {
        previewFileQueue.addAll(absFilenames);
        List<Future<HashMap<String, byte[]>>> futures = new ArrayList<>();
        for (int i = 0; i < 3; i++) {
            futures.add(executorService.submit(new Callable<HashMap<String, byte[]>>() {
                @Override
                public HashMap<String, byte[]> call() throws Exception {
                    return getPreviewFileWorker(share);
                }
            }));
        }
        HashMap<String, byte[]> res = new HashMap<>();
        for (Future<HashMap<String, byte[]>> future : futures) {
            try {
                HashMap<String, byte[]> m = future.get();
                if (m != null) {
                    res.putAll(m);
                }
            } catch (Exception e) {
                Logger.e(ExceptionUtils.getStackTrace(e));
            }
        }
        return res;
    }

}