package com.example.raising

import com.example.raising.exception.SmbException
import com.example.raising.exception.SmbInterruptException
import com.example.raising.vo.DirectoryVO
import com.example.raising.vo.SmbCO
import com.example.raising.vo.SmbResult
import com.example.raising.vo.ZipFileContentCO
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
import net.sf.sevenzipjbinding.ExtractOperationResult
import net.sf.sevenzipjbinding.IInArchive
import net.sf.sevenzipjbinding.SevenZip
import net.sf.sevenzipjbinding.SevenZipException
import net.sf.sevenzipjbinding.simple.ISimpleInArchiveItem
import org.apache.commons.lang3.StringUtils
import org.apache.commons.lang3.exception.ExceptionUtils
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.RandomAccessFile
import java.util.*
import java.util.concurrent.*


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
                if (StringUtils.isEmpty(co.absPath) || co.absPath == "/" || co.absPath == "\\") { //return share;
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
                val shareName = co.shareName
                val path = co.path
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


    /**
     * 需求：子任务必须要原子化，batch要在这些子任务中实现，能够中断文件传输，最好也能返回batch中已完成的任务
     * 返回batch中已完成的任务：所以异常处理不能用throw，要存中间结果跟错误码，
     * 原子化：但由于顺序访问应该更快，所以同一个smb连接还是要处理同一个压缩文件下的子文件。
     * 中断文件传输，就需要shutdown 线程池，处理好中断信号Thread.currentThread().isInterrupted()
     */
    private val fileIndexTask = ConcurrentHashMap<String, ConcurrentSkipListSet<Int>>()
    private val executorService = Executors.newFixedThreadPool(3)

    private const val interrupttime = 100

    @Throws(SevenZipException::class, SmbException::class)
    private fun extractItem(item: ISimpleInArchiveItem, hash: IntArray, proto: ZipFileContentCO): ZipFileContentCO {

        val begin = System.currentTimeMillis()
        val result: ExtractOperationResult
        val sizeArray = LongArray(1)
        val outputStream = ByteArrayOutputStream()
        result = item.extractSlow { data ->
            //处理线程中断，这里不会马上处理中断，因为假设一个文件传输很快
            if (Thread.currentThread().isInterrupted && System.currentTimeMillis() - begin > interrupttime) {
                throw SmbInterruptException("thread interrupt")
            }
            hash[0] = hash[0] xor Arrays.hashCode(data) // Consume data
            sizeArray[0] = sizeArray[0] + data.size
            try {
                outputStream.write(data)
            } catch (e: IOException) {
                Logger.e(e, "extractItem error")
            }
            data.size // Return amount of consumed data
        }
        return if (result == ExtractOperationResult.OK) {
            Logger.i("extreactItem path %s size %d use %d ms.", item.path, sizeArray[0], System.currentTimeMillis() - begin)
            val copy: ZipFileContentCO = proto.copy();
            copy.zipAbsFilename = item.path;
            copy.content = outputStream.toByteArray();
            copy
        } else {
            Logger.e("Error extracting item: $result")
            throw SmbException("Error extracting item:$result")
        }
    }


    //由于中断的存在，本函数不一定能返回全部图片
    @Throws(java.lang.Exception::class)
    private fun getFileWorker(absFilename: String, needFileDetailInfo: Boolean, indexs: List<Int>, share: DiskShare): SmbResult {
        var res = HashMap<Int, ZipFileContentCO>()
        //        ConcurrentSkipListSet<Integer> indexlst = fileIndexTask.get(absFilename);
        val indexlst: Set<Int> = HashSet(indexs)
        if (indexlst == null || indexlst.isEmpty()) {
            return SmbResult.ofEmptyIndex().setZipFiles(res)
        }
        Logger.i("previewFileQueue file name %s", absFilename)
        val f: File? = null
        val fileExists = share.fileExists(absFilename)
        if (!fileExists) {
            Logger.w("File %s not exist.", absFilename)
            throw SmbException("File $absFilename not exist")
        }
        val smbFileRead = share.openFile(absFilename, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null)
        val info = smbFileRead.getFileInformation(FileStandardInformation::class.java)
        val `in` = smbFileRead.inputStream
        val randomAccessFile: RandomAccessFile? = null
        var inArchive: IInArchive? = null
        return try {
            inArchive = SevenZip.openInArchive(null,  // autodetect archive type
                    SmbRandomFile(smbFileRead))
            val simpleInArchive = inArchive.simpleInterface
            val proto = ZipFileContentCO()
            proto.length = simpleInArchive.archiveItems.size
            proto.absFilename = (absFilename)
            val paths = ArrayList<String>()
            val mapPath = HashMap<String, Int>()
            var archiIndex = 0
            val getAchiveItemTime = System.currentTimeMillis()
            for (item in simpleInArchive.archiveItems) {
                if (!item.isFolder) {
                    paths.add(item.path)
                    mapPath[item.path] = archiIndex++
                }
            }
            Logger.d("iterate archiveItems name use %d ms", System.currentTimeMillis() - getAchiveItemTime)
            paths.sortBy { it }
            for (integer in indexlst) {
                val hash = intArrayOf(0)
                if (Thread.currentThread().isInterrupted) {
                    return SmbResult.ofCancel().setZipFiles(res)
                } else if (integer >= 0 && integer < paths.size) {
                    val extractItem = extractItem(simpleInArchive.getArchiveItem(mapPath[paths[integer]]!!), hash, proto)
                    extractItem.index = integer
                    res[integer] = extractItem
                } else {
                    Logger.d("SmbHalfResult.ofContainNotExistIndex page %d ", integer)
                    return SmbResult.ofContainNotExistIndex().setZipFiles(res)
                }
            }
            SmbResult.ofSuccessful().setZipFiles(res)
        } catch (e: SmbInterruptException) {
            Logger.e("Error closing file: " + ExceptionUtils.getStackTrace(e))
            SmbResult.ofCancel().setZipFiles(res)
        } catch (e: java.lang.Exception) {
            Logger.e(e, absFilename)
            SmbResult.ofUnknownError().setZipFiles(res)
        } finally {
            if (inArchive != null) {
                try {
                    inArchive.close()
                } catch (e: SevenZipException) {
                    Logger.e("Error closing archive: $e")
                }
            }
            if (randomAccessFile != null) {
                try {
                    randomAccessFile.close()
                } catch (e: IOException) {
                    Logger.e("Error closing file: $e")
                }
            }
        }
    }

    @Throws(SmbException::class)
    fun loadFileFromZip(indexs: ArrayList<Int>, needFileDetailInfo: Boolean, co: SmbCO): SmbResult? {

        val absFilename = co.path
        return getShare(co
        ) { share ->
            val task: Future<SmbResult> = executorService.submit(Callable { getFileWorker(absFilename, needFileDetailInfo, indexs, share) })
            try {
                task.get()
            } catch (e: CancellationException) {
                Logger.e(e, "%s %s", absFilename, indexs.toString())
                try { //睡眠一小段时间，是为了传输完成正在传输中的图片
                    Thread.sleep(130)
                    task.get()
                } catch (ex: java.lang.Exception) {
                    Logger.e(e, "double %s %s", absFilename, indexs.toString())
                    SmbResult.ofCancel()
                }
            } catch (e: java.lang.Exception) {
                Logger.e(e, "%s %s", absFilename, indexs.toString())
                SmbResult.ofUnknownError()
            }

        }


    }


    @Throws(SmbException::class)
    fun loadWholeFile(co: SmbCO): SmbResult? {

        return getShare(co
        ) { share ->
            val absPath = co.path
            val task: Future<SmbResult> = executorService.submit(Callable {
                val f: File? = null
                val fileExists = share.fileExists(absPath)
                if (!fileExists) {
                    Logger.w("File %s not exist.", absPath)
                    throw SmbException("File $absPath not exist")
                }
                try {
                    val smbFileRead = share.openFile(absPath, EnumSet.of(AccessMask.GENERIC_READ), null, SMB2ShareAccess.ALL, SMB2CreateDisposition.FILE_OPEN, null)
                    val info = smbFileRead.getFileInformation(FileStandardInformation::class.java)
                    val `in` = smbFileRead.inputStream
                    val buffer = ByteArrayOutputStream()
                    var nRead: Int
                    val data = ByteArray(16384)
                    var total = 0
                    while (`in`.read(data, 0, data.size).also { nRead = it } != -1) {
                        buffer.write(data, 0, nRead)
                        total += nRead
                    }
                    val imagebyte = buffer.toByteArray()
                    val res = HashMap<Int, ZipFileContentCO>()
                    val zipFileContentCO = ZipFileContentCO()
                    zipFileContentCO.absFilename = absPath;
                    zipFileContentCO.content = (imagebyte);
                    zipFileContentCO.index = (0);
                    zipFileContentCO.length = (total);

                    res[0] = zipFileContentCO
                    return@Callable SmbResult.ofSuccessful().setZipFiles(res)
                } catch (e: java.lang.Exception) {
                    Logger.e(e, "cannot load image file")
                    throw SmbException(e.message)
                }
            })
            try {
                task.get()
            } catch (e: CancellationException) {
                Logger.e(e, "%s", absPath)
                try { //睡眠一小段时间，是为了传输完成正在传输中的图片
                    Thread.sleep(130)
                    task.get()
                } catch (ex: java.lang.Exception) {
                    Logger.e(e, "double %s", absPath)
                    SmbResult.ofCancel()
                }
            } catch (e: java.lang.Exception) {
                Logger.e(e, "%s", absPath)
                SmbResult.ofUnknownError()
            }
        }

    }

    fun stopSmbRequest() {
        fileIndexTask.clear()
        val runnables = executorService.shutdownNow()
    }

    private fun getSmbClient(): SMBClient {
        val config = SmbConfig.builder()
                .withTimeout(30, TimeUnit.SECONDS) // Timeout sets Read, Write, and Transact timeouts (default is 60 seconds)
                .withSoTimeout(30, TimeUnit.SECONDS) // Socket Timeout (default is 0 seconds, blocks forever)
                .build()
        return SMBClient(config)
    }

    private fun <T> getShare(co: SmbCO, pro: (disk: DiskShare) -> T): T {
        Logger.d("getShare: current smb setting %s", co)
        val client: SMBClient = getSmbClient()
        try {
            client.connect(co.hostname).use { connection ->
                val ac: AuthenticationContext = if (co.password != null) {
                    AuthenticationContext(co.username, co.password.toCharArray(), co.domain)
                } else {
                    AuthenticationContext.guest()
                }
                val session = connection.authenticate(ac)
                // Connect to Share
                try {
                    val diskShare = session.connectShare(co.shareName) as DiskShare
                    return pro(diskShare)
                } catch (e: java.lang.Exception) {
                    Logger.e(ExceptionUtils.getStackTrace(e))
                    throw e;
                }
            }
        } catch (e: java.lang.Exception) {
            Logger.e(ExceptionUtils.getStackTrace(e))
            throw e;
        }
    }

}
