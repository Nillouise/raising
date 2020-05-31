package com.example.raising

import androidx.annotation.NonNull
import com.orhanobut.logger.AndroidLogAdapter
import com.orhanobut.logger.Logger
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.MethodDispatcher


class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine);

//        val policy = StrictMode.ThreadPolicy.Builder().permitAll().build()
//        StrictMode.setThreadPolicy(policy)

        MethodChannel(flutterEngine.dartExecutor, "nil/channel").setMethodCallHandler(MethodDispatcher())
        Logger.addLogAdapter(AndroidLogAdapter())
    }
}
