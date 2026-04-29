package com.mybutler.launcher_app

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
            
            // 基本情報の取得
            val title = extras.getString("android.title") ?: ""
            val text = extras.getCharSequence("android.text")?.toString() ?: ""
            
            // メッセンジャー特有の情報の取得
            val conversationTitle = extras.getCharSequence("android.conversationTitle")?.toString() ?: ""
            val isGroupChat = extras.getBoolean("android.isGroupConversation")
            
            // 送信者名の特定 (MessagingStyleから)
            val sender = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                extras.getCharSequence("android.messagingStyleUser")?.toString() ?: title
            } else {
                title
            }

            val data = mutableMapOf(
                "packageName" to packageName,
                "title" to title,
                "text" to text,
                "sender" to sender,
                "conversationTitle" to conversationTitle,
                "isGroupChat" to isGroupChat,
                "timestamp" to it.postTime
            )
            
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                channel?.invokeMethod("onNotificationReceived", data)
            }
        }
    }
}
