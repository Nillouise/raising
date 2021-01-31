package com.example.raising

object Utils{
    fun splitPath(absPath: String): List<String> {
        return absPath.split("[/\\\\]".toRegex()).filter { x -> !x.isBlank() };
    }
}
