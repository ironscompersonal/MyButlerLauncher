package com.example.ai_butler_launcher

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.ai_butler_launcher/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        MyNotificationListener.channel = channel
        
        channel.setMethodCallHandler { call, result ->
            if (call.method == "checkNotificationPermission") {
                result.success(true) 
            } else {
                result.notImplemented()
            }
        }
    }
}
