package com.example.raising

import com.example.raising.vo.DirectoryVO
import com.example.raising.vo.SmbCO
import com.hierynomus.msfscc.FileAttributes
import com.hierynomus.protocol.commons.EnumWithValue
import com.hierynomus.smbj.SMBClient
import com.hierynomus.smbj.SmbConfig
import com.hierynomus.smbj.auth.AuthenticationContext
import com.hierynomus.smbj.share.DiskShare
import com.orhanobut.logger.Logger
import com.rapid7.client.dcerpc.mssrvs.ServerService
import com.rapid7.client.dcerpc.transport.SMBTransportFactories
import org.apache.commons.lang3.StringUtils
import java.util.*
import java.util.concurrent.TimeUnit


object SmbChannel {
    // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
    // Socket Timeout (default is 0 seconds, blocks forever)
    private val client: SMBClient
        get() {
            val config = SmbConfig.builder()
                    .withTimeout(30, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
                    .withSoTimeout(30, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
                    .build()
            return SMBClient(config)
        }

    @Throws(Exception::class)
    fun queryFiles(co: SmbCO): ArrayList<DirectoryVO> {
        val client = client
        Logger.d("queryFiles: current smb setting %s", co)
        try {
            client.connect(co.hostname).use { connection ->
                val ac: AuthenticationContext = if (co.password != null) {
                    AuthenticationContext(co.username, co.password.toCharArray(), co.domain)
                } else {
                    AuthenticationContext.anonymous()
                }
                val session = connection.authenticate(ac)
                if (StringUtils.isEmpty(co.wholePath) || co.wholePath == "/" || co.wholePath == "\\\\") { //return share;
                    val transport = SMBTransportFactories.SRVSVC.getTransport(session)
                    val serverService = ServerService(transport)
                    val shares = serverService.shares0
                    val resShare: ArrayList<DirectoryVO> = ArrayList()
                    for (share in shares) {
                        resShare.add(DirectoryVO().apply {
                            filename = share.netName
                            isDirectory = true;
                            isShare = true;
                        });
                    }
                    return resShare;
                }
                val split = co.wholePath.split("[/\\\\\\\\]")
                val shareName = split[0]
                val path = split.subList(1, split.size).joinToString("/")
                val res = ArrayList<DirectoryVO>()
                // Connect to Share
                try {
                    (session.connectShare(shareName) as DiskShare).use { share ->
                        for (f in share.list(path)) {
                            res.add(DirectoryVO().apply {
                                filename = f.fileName;
                                size = f.endOfFile;
                                updateTime = f.lastWriteTime.toDate();
                                isDirectory = EnumWithValue.EnumUtils.isSet(f.fileAttributes, FileAttributes.FILE_ATTRIBUTE_DIRECTORY);
                            });
                        }
                    }
                } catch (e: Exception) {
                    Logger.e(e, "SmbCO %s ", co)
                    throw e
                }
                return res
            }
        } catch (e: Exception) {
            Logger.e(e, "SmbCO %s", co)
            throw e
        }
    }
}
