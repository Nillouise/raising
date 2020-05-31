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
import com.hierynomus.smbj.share.Share;
import com.orhanobut.logger.Logger;

import net.sf.sevenzipjbinding.IInArchive;
import net.sf.sevenzipjbinding.PropID;
import net.sf.sevenzipjbinding.SevenZip;
import net.sf.sevenzipjbinding.impl.RandomAccessFileInStream;

import org.apache.commons.lang3.exception.ExceptionUtils;

import java.io.*;
import java.util.*;
import java.util.concurrent.TimeUnit;

import io.flutter.plugins.exception.SmbException;

interface ProcessShare<T> {
    T process(DiskShare share);
}

public class Smb {

    private SMBClient getClient() {
        SmbConfig config = SmbConfig.builder()
                .withTimeout(30, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
                .withSoTimeout(30, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
                .build();
        SMBClient client = new SMBClient(config);
        return client;
    }


    public ArrayList<String> listFile(String hostname, String shareName, String domain, String username, String passwrod, String path, String searchPattern) {
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
                    res.add(f.getFileName());
                }
            } catch (Exception e) {
                res.add("ErrorMessage: " + e.toString());
                Logger.e(ExceptionUtils.getStackTrace(e));
            }
        } catch (Exception e) {
            res.add("ErrorMessage: " + e.toString());
            Logger.e(ExceptionUtils.getStackTrace(e));
        }
        return res;
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

    public byte[] getFile(String hostname, String shareName, String domain, String username, String passwrod, String path, String searchPattern) throws SmbException {
        Smb smb = new Smb();
        return smb.processShare(hostname, shareName, domain, username, passwrod, path, searchPattern,
                share -> {
                    try {
                        return smb.getFile(path, share);
                    } catch (Exception e) {
                        Logger.i(ExceptionUtils.getStackTrace(e));
                    }
                    return null;
                }

        );
    }

    public static void listZip(final String filename, DiskShare share) throws SmbException {
        Logger.i("begin to list Zip 2");
        Logger.i("filename is"+filename);
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
}