package com.example.raising

import com.example.raising.vo.ExtractCO
import com.example.raising.vo.SmbResult
import com.orhanobut.logger.Logger
import net.sf.sevenzipjbinding.*
import org.apache.commons.lang3.exception.ExceptionUtils
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.util.*


object ExtractChannel {

    /**
     * 如何在多文件、多线程（获取网络数据的多线程，解压的多线程）下进行extract的优化?
     * 要避免获取网络数据的连接重建，应当使用连接池（即使是smb的单个文件，应该也缓存获得单个文件的smb连接）
     * 另一方面，由于单页查看其实需要的网络流量跟延迟应该很小，而且也容易缓存图像，所以不需要对这个进行优化。
     * 需要优化的是一下子生成所有预览图的情况，包括多个文件的预览图，以及单个压缩文件内的所有图。
     *
     * 由于多个文件的预览图无法优化（即一个解压线程只能对应一个文件），单个文件的所有图不需要优化（遍历一遍即可），
     * 解压单个文件的其中一些文件可以优化，但这个需求不急切。
     */
    @Throws(java.lang.Exception::class)
    public fun extract(fileStream: IInStream, index: Int): ExtractCO {
        var inArchive: IInArchive? = null
        val outputStream = ByteArrayOutputStream()
        val res = ExtractCO();
        try {
            inArchive = SevenZip.openInArchive(null,  // autodetect archive type
                    fileStream)
            // Getting simple interface of the archive inArchive
            val simpleInArchive = inArchive.simpleInterface
//            println("   Hash   |    Size    | Filename")
//            println("----------+------------+---------")
//            simpleInArchive.getArchiveItem(index);

            var i = 0;
            res.apply {
                indexContent = HashMap<Int, ByteArray>();
                indexPath = HashMap<Int, String>();
                compressFormat = inArchive.archiveFormat.name;
                fileNum = simpleInArchive.numberOfItems;
            }
            for (item in simpleInArchive.archiveItems) {
                val hash = intArrayOf(0)
                if (!item.isFolder) {
                    res.indexPath!![i] = item.path ?: "";
                    if (i == index) {
                        var result: ExtractOperationResult
                        val sizeArray = LongArray(1)
                        result = item.extractSlow { data ->
                            hash[0] = hash[0] xor Arrays.hashCode(data) // Consume data
                            sizeArray[0] = sizeArray[0] + data.size
                            outputStream.write(data);
                            data.size // Return amount of consumed data
                        }
                        return if (result == ExtractOperationResult.OK) {
//                            println(String.format("%9X | %10s | %s",
//                                    hash[0], sizeArray[0], item.path))
                            res.apply {
                                msg = "OK";
                                indexContent!![i] = outputStream.toByteArray();
                                isCompressFile = true;
                            }
                        } else {
                            //System.err.println("Error extracting item: $result")
                            res.apply {
                                msg = "Extract error :$result";
                            }
                        }
                    }
                    i++;
                }
            }
            return res.apply {
                msg = "index $index does not exist";
            }
        } catch (e: java.lang.Exception) {
            Logger.e(e, "extract error")
            return res.apply {
                msg = e.toString();
            }
        } finally {
            if (inArchive != null) {
                try {
                    inArchive.close()
                } catch (e: SevenZipException) {
                    Logger.e("Error closing archive: $e")
                }
            }
            try {
                fileStream.close()
            } catch (e: IOException) {
                Logger.e("Error closing file: $e")
            }
        }
    }


//    @Throws(SevenZipException::class, SmbException::class)
//    private fun extractItem(item: ISimpleInArchiveItem, hash: IntArray, proto: ZipFileContentCO): ZipFileContentCO {
//
//        val begin = System.currentTimeMillis()
//        val result: ExtractOperationResult
//        val sizeArray = LongArray(1)
//        val outputStream = ByteArrayOutputStream()
//        result = item.extractSlow { data ->
//            //处理线程中断，这里不会马上处理中断，因为假设一个文件传输很快
//            if (Thread.currentThread().isInterrupted && System.currentTimeMillis() - begin > SmbChannel.interrupttime) {
//                throw SmbInterruptException("thread interrupt")
//            }
//            hash[0] = hash[0] xor Arrays.hashCode(data) // Consume data
//            sizeArray[0] = sizeArray[0] + data.size
//            try {
//                outputStream.write(data)
//            } catch (e: IOException) {
//                Logger.e(e, "extractItem error")
//            }
//            data.size // Return amount of consumed data
//        }
//        return if (result == ExtractOperationResult.OK) {
//            Logger.i("extreactItem path %s size %d use %d ms.", item.path, sizeArray[0], System.currentTimeMillis() - begin)
//            val copy: ZipFileContentCO = proto.copy();
//            copy.zipAbsFilename = item.path;
//            copy.content = outputStream.toByteArray();
//            copy
//        } else {
//            Logger.e("Error extracting item: $result")
//            throw SmbException("Error extracting item:$result")
//        }
//    }

//    @Throws(java.lang.Exception::class)
//    public fun queryItems(fileStream: IInStream): SmbResult {
//        var inArchive: IInArchive? = null
//        try {
//            inArchive = SevenZip.openInArchive(null,  // autodetect archive type
//                    fileStream)
//            // Getting simple interface of the archive inArchive
//            val simpleInArchive = inArchive.simpleInterface
//            println("   Size   | Compr.Sz. | Filename")
//            println("----------+-----------+---------")
//            var path: String = "";
//            for (item in simpleInArchive.archiveItems) {
//                println(String.format("%9s | %9s | %s",  //
//                        item.size,
//                        item.packedSize,
//                        item.path))
//                path = item.path;
//            }
//            return SmbResult().setMsg(path);
//        } catch (e: Exception) {
//            System.err.println("Error occurs: " + ExceptionUtils.getStackTrace(e));
//            return SmbResult().setMsg("error exception");
//        } finally {
//            if (inArchive != null) {
//                try {
//                    inArchive.close()
//                } catch (e: SevenZipException) {
//                    System.err.println("Error closing archive: $e")
//                }
//            }
//            try {
//                fileStream.close()
//            } catch (e: IOException) {
//                System.err.println("Error closing file: $e")
//            }
//        }
//    }
}
