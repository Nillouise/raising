package com.example.raising.smb2

import com.example.raising.vo.DirectoryVO
import com.example.raising.vo.ExploreCO
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
import java.util.ArrayList
import java.util.concurrent.TimeUnit

object SmbChannel2 {

    private val client: SMBClient
        get() {
            val config = SmbConfig.builder()
                    .withTimeout(10, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
                    .withSoTimeout(10, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
                    .build()
            return SMBClient(config)
        }

    fun getShare(absPath:String): String {
        val split: Array<String> = absPath.split("[/\\\\]").toTypedArray()
        return if (split.isEmpty()) {
            ""
        } else split[0]
    }

    @Throws(Exception::class)
    fun queryFiles(co: SmbHost, absPath: String): ArrayList<ExploreCO> {
        Logger.d("queryFiles: current smb setting %s", co)
        try {
            client.connect(co.getOnlyHostname()).use { connection ->
                val ac: AuthenticationContext = if (!co.password.isBlank()) {
                    AuthenticationContext(co.username, co.password.toCharArray(), co.domain)
                } else {
                    AuthenticationContext.anonymous()
                }
                val session = connection.authenticate(ac)
                if (StringUtils.isEmpty(absPath) || absPath == "/" || absPath == "\\") { //return share;
                    val transport = SMBTransportFactories.SRVSVC.getTransport(session)
                    val serverService = ServerService(transport)
                    val shares = serverService.shares0
                    val resShare: ArrayList<ExploreCO> = ArrayList()
                    for (share in shares) {
                        resShare.add(ExploreCO().apply {
                            this.absPath = "/" + share.netName
                            filename = share.netName
                            isDirectory = true
                        });
                    }
                    return resShare;
                }
                val shareName = getShare(absPath)
                val res = ArrayList<ExploreCO>()
                // Connect to Share
                try {
                    (session.connectShare(shareName) as DiskShare).use { share ->
                        for (f in share.list(absPath)) {
                            res.add(ExploreCO().apply {
                                filename = f.fileName;
                                size = f.endOfFile;
                                updateTime = f.lastWriteTime.toDate();
                                createTime = f.creationTime.toDate()
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