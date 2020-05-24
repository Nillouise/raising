package com.example.raising

import android.os.StrictMode
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.Smb

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
        StrictMode.setThreadPolicy(policy)

        MethodChannel(flutterEngine.dartExecutor, "nil/channel").setMethodCallHandler { call, result ->
            if (call.method == "smbList") {
                println(call.arguments)
                val res = Smb().listFile(call.argument<String>("hostname"),
                        call.argument<String>("shareName"),
                        call.argument<String>("domain"),
                        call.argument<String>("username"),
                        call.argument<String>("password"),
                        call.argument<String>("path"),
                        call.argument<String>("searchPattern"));
                result.success(res)
            } else if (call.method == "getFile") {
                println(call.arguments)
                val res = Smb().getFile(call.argument<String>("hostname"),
                        call.argument<String>("shareName"),
                        call.argument<String>("domain"),
                        call.argument<String>("username"),
                        call.argument<String>("password"),
                        call.argument<String>("path"),
                        call.argument<String>("searchPattern"));
                result.success(res)
            } else {
                result.notImplemented()
            }
        }
    }
}
