package com.example.raising.smb2

import org.apache.commons.lang3.StringUtils
import java.util.*

class SmbHost {
    var username: String = ""
    var password: String = ""
    var hostname: String = ""
    var domain: String = ""

    fun getOnlyHostname(): String {
        val split: Array<String> = hostname.split("[/\\\\]").toTypedArray()
        return if (split.isEmpty()) {
            ""
        } else split[0]
    }

    override fun toString(): String {
        return "SmbHost(username='$username', password='$password', absPathLink='$hostname', domain='$domain')"
    }


    companion object {
        fun fromMap(map: HashMap<String, String>): SmbHost {
            val host = SmbHost()
            host.username = map["username"] ?: ""
            host.password = map["password"] ?: ""
            host.hostname = map["hostname"] ?: ""
            host.domain = map["domain"] ?: ""
            return host
        }
    }


}