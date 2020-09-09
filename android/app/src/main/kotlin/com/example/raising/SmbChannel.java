//package com.example.raising;
//
//import com.example.raising.vo.DirectoryVO;
//import com.hierynomus.msfscc.fileinformation.FileIdBothDirectoryInformation;
//import com.hierynomus.protocol.commons.EnumWithValue;
//import com.hierynomus.smbj.SMBClient;
//import com.hierynomus.smbj.SmbConfig;
//import com.hierynomus.smbj.auth.AuthenticationContext;
//import com.hierynomus.smbj.connection.Connection;
//import com.hierynomus.smbj.session.Session;
//import com.hierynomus.smbj.share.DiskShare;
//import com.orhanobut.logger.Logger;
//import com.rapid7.client.dcerpc.mssrvs.ServerService;
//import com.rapid7.client.dcerpc.mssrvs.dto.NetShareInfo0;
//import com.rapid7.client.dcerpc.transport.RPCTransport;
//import com.rapid7.client.dcerpc.transport.SMBTransportFactories;
//
//import org.apache.commons.lang3.StringUtils;
//
//import java.util.*;
//import java.util.concurrent.TimeUnit;
//
//import com.example.raising.vo.SmbCO;
//
//import static com.hierynomus.msfscc.FileAttributes.FILE_ATTRIBUTE_DIRECTORY;
//
//public class SmbChannel {
//
//    private static SMBClient getClient() {
//        SmbConfig config = SmbConfig.builder()
//                .withTimeout(30, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
//                .withSoTimeout(30, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
//                .build();
//        SMBClient client = new SMBClient(config);
//        return client;
//    }
//
//
//    public static ArrayList<DirectoryVO> queryFiles(SmbCO co) throws Exception {
//        ArrayList<FileInfo> res = new ArrayList<FileInfo>();
//        SMBClient client = getClient();
//
//        Logger.d("queryFiles: current smb setting %s", co);
//        try (Connection connection = client.connect(co.getHostname())) {
//            AuthenticationContext ac;
//            if (co.getPassword() != null) {
//                ac = new AuthenticationContext(co.getUsername(), co.getPassword().toCharArray(), co.getDomain());
//            } else {
//                ac = AuthenticationContext.anonymous();
//            }
//            Session session = connection.authenticate(ac);
//
//            if (StringUtils.isEmpty(co.getWholePath()) || co.getWholePath().equals("/") || co.getWholePath().equals("\\\\")) {
//                //return share;
//                final RPCTransport transport = SMBTransportFactories.SRVSVC.getTransport(session);
//                final ServerService serverService = new ServerService(transport);
//                final List<NetShareInfo0> shares = serverService.getShares0();
//                List<DirectoryVO> resShare = new ArrayList<>();
//                for (final NetShareInfo0 share : shares) {
//                    resShare.add(new DirectoryVO(share.getNetName(), new Date(), 0);
//                    share.getNetName());
//                }
//                return res;
//            }
//
//            String[] split = co.getWholePath().split("[/\\\\\\\\]");
//            String shareName = split[0];
//            split[0] = null;
//            String path = String.join("/", split);
//
//            // Connect to Share
//            try (DiskShare share = (DiskShare) session.connectShare(shareName)) {
//                for (FileIdBothDirectoryInformation f : share.list(path)) {
//                    FileInfo fi = new FileInfo()
//                            .setFilename(f.getFileName())
//                            .setSize(f.getEndOfFile())
//                            .setUpdateTime(f.getLastWriteTime().toDate())
//                            .setDirectory(EnumWithValue.EnumUtils.isSet(f.getFileAttributes(), FILE_ATTRIBUTE_DIRECTORY));
//                    res.add(fi);
//                }
//            } catch (Exception e) {
//                Logger.e(e, "SmbCO %s ", co);
//                throw e;
//            }
//            return res;
//        } catch (Exception e) {
//            Logger.e(e, "SmbCO %s", co);
//            throw e;
//        }
//    }
//}
