package com.example.raising.smb2

import com.example.raising.SmbRandomFile
import com.example.raising.Utils
import com.example.raising.exception.SmbException
import com.example.raising.vo.ExploreCO
import com.hierynomus.msdtyp.AccessMask
import com.hierynomus.msfscc.FileAttributes
import com.hierynomus.msfscc.fileinformation.FileStandardInformation
import com.hierynomus.mssmb2.SMB2CreateDisposition
import com.hierynomus.mssmb2.SMB2ShareAccess
import com.hierynomus.protocol.commons.EnumWithValue
import com.hierynomus.smbj.SMBClient
import com.hierynomus.smbj.SmbConfig
import com.hierynomus.smbj.auth.AuthenticationContext
import com.hierynomus.smbj.share.DiskShare
import com.hierynomus.smbj.share.File
import com.orhanobut.logger.Logger
import com.rapid7.client.dcerpc.mssrvs.ServerService
import com.rapid7.client.dcerpc.transport.SMBTransportFactories
import net.sf.sevenzipjbinding.IInArchive
import org.apache.commons.lang3.StringUtils
import java.io.RandomAccessFile
import java.util.*
import java.util.concurrent.TimeUnit

object SmbChannel2 {

    private val defaultClient: SMBClient
        get() {
            val config = SmbConfig.builder()
                    .withTimeout(10, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
                    .withSoTimeout(10, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
                    .build()
            return SMBClient(config)
        }
    

    private fun getShare(absPath: String): String {
        val split = Utils.splitPath(absPath)
        return if (split.isEmpty()) {
            ""
        } else split[0]
    }

    private fun getPathOfShare(absPath: String): String {
        val split = Utils.splitPath(absPath)
        return if (split.size <= 1) {
            ""
        } else split.subList(1, split.size).joinToString("\\")
    }

    private fun getClient(host: SmbHost): SMBClient {
        return defaultClient
    }

    @Throws(Exception::class)
    fun queryFiles(host: SmbHost, absPath: String): ArrayList<ExploreCO> {
        Logger.d("queryFiles: current smb setting %s", host)
        try {
            val client = getClient(host);
            client.connect(host.getOnlyHostname()).use { connection ->
                val ac: AuthenticationContext = if (!host.password.isBlank()) {
                    AuthenticationContext(host.username, host.password.toCharArray(), host.domain)
                } else {
                    AuthenticationContext.anonymous()
                }

                ///处理没选share的情况
                val session = connection.authenticate(ac)
                return if (StringUtils.isEmpty(absPath) || absPath == "/" || absPath == "\\") { //return share;
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
                    resShare;
                } else {
                    ///处理选了share的情况
                    val shareName = getShare(absPath)
                    val path = getPathOfShare(absPath)
                    Logger.d("current path $path shareName $shareName")
                    val res = ArrayList<ExploreCO>()
                    // Connect to Share
                    try {
                        (session.connectShare(shareName) as DiskShare).use { share ->
                            for (f in share.list(path)) {
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
                        Logger.e(e, "SmbHost %s ", host)
                        throw e
                    }
                    res
                }
            }
        } catch (e: Exception) {
            Logger.e(e, "SmbHost %s", host)
            throw e
        }
    }


    @Throws(Exception::class)
    fun getFileStream(host: SmbHost, absPath: String): SmbRandomFile {
        Logger.d("queryFiles: current smb setting %s", host)
        try {
            val client = getClient(host);
            val shareName = getShare(absPath)
            val path = getPathOfShare(absPath)

            if (StringUtils.isEmpty(path) || path == "/" || path == "\\") {
                throw SmbException("not a file");
            }

            client.connect(host.getOnlyHostname()).use { connection ->
                val ac: AuthenticationContext = if (!host.password.isBlank()) {
                    AuthenticationContext(host.username, host.password.toCharArray(), host.domain)
                } else {
                    AuthenticationContext.anonymous()
                }

                ///处理没选share的情况
                val session = connection.authenticate(ac)

                try {
                    (session.connectShare(shareName) as DiskShare).use { share ->
                        Logger.i("previewFileQueue file name %s", path)
                        val f: File? = null
                        val fileExists = share.fileExists(path)
                        if (!fileExists) {
                            Logger.w("File %s not exist.", path)
                            throw SmbException("File $path not exist")
                        }
                        val smbFileRead = share.openFile(path, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null)
                        val info = smbFileRead.getFileInformation(FileStandardInformation::class.java)
                        val `in` = smbFileRead.inputStream
                        val randomAccessFile: RandomAccessFile? = null
                        var inArchive: IInArchive? = null
                        return SmbRandomFile(smbFileRead)
                    }
                } catch (e: Exception) {
                    Logger.e(e, "SmbHost %s ", host)
                    throw e
                }
            }
        } catch (e: Exception) {
            Logger.e(e, "SmbHost %s", host)
            throw e
        }

    }

}