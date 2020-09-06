package io.flutter.plugins;

import com.hierynomus.msfscc.fileinformation.FileIdBothDirectoryInformation;
import com.hierynomus.protocol.commons.EnumWithValue;
import com.hierynomus.smbj.SMBClient;
import com.hierynomus.smbj.SmbConfig;
import com.hierynomus.smbj.auth.AuthenticationContext;
import com.hierynomus.smbj.connection.Connection;
import com.hierynomus.smbj.session.Session;
import com.hierynomus.smbj.share.DiskShare;
import com.orhanobut.logger.Logger;

import java.util.*;
import java.util.concurrent.TimeUnit;

import io.flutter.plugins.exception.SmbException;
import io.flutter.plugins.exception.SmbInterruptException;

import static com.hierynomus.msfscc.FileAttributes.FILE_ATTRIBUTE_DIRECTORY;

public class SmbChannel {

    private static SMBClient getClient() {
        SmbConfig config = SmbConfig.builder()
                .withTimeout(30, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
                .withSoTimeout(30, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
                .build();
        SMBClient client = new SMBClient(config);
        return client;
    }

    public static ArrayList<FileInfo> queryFiles(SmbCO po) throws Exception {
        ArrayList<FileInfo> res = new ArrayList<FileInfo>();
        SMBClient client = getClient();
        String hostname = po.hostname.split("/")[0];

        Logger.d("queryFiles: current smb setting %s", po);
        try (Connection connection = client.connect(hostname)) {
            AuthenticationContext ac;
            if (passwrod != null) {
                ac = new AuthenticationContext(po.username, po.passwrod.toCharArray(), po.domain);
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
}
