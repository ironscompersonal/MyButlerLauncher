package com.example.ai_butler_launcher

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.content.Intent
import android.os.IBinder
import io.flutter.plugin.common.MethodChannel

class MyNotificationListener : NotificationListenerService() {
    
    companion object {
        var instance: MyNotificationListener? = null
        var channel: MethodChannel? = null
    }

    override fun onBind(intent: Intent?): IBinder? {
        instance = this
        return super.onBind(intent)
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn?.let {
            val packageName = it.packageName
            val extras = it.notification.extras
            val title = extras.getString("android.title") ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            
            val data = mapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to text,
                "timestamp" to it.postTime
            )
            
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                channel?.invokeMethod("onNotificationReceived", data)
            }
        }
    }
}
