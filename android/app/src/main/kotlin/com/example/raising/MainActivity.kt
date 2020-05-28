package com.example.raising

import android.os.StrictMode
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.MethodDispatcher
import io.flutter.plugins.Smb

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

//        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
//        StrictMode.setThreadPolicy(policy)

        MethodChannel(flutterEngine.dartExecutor, "nil/channel").setMethodCallHandler(MethodDispatcher())
    }
}
