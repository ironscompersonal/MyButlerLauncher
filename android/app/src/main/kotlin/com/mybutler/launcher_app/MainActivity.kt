package com.mybutler.launcher_app

import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import java.io.ByteArrayOutputStream
import java.security.MessageDigest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.mybutler.launcher_app/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        MyNotificationListener.channel = channel
        
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkNotificationPermission" -> {
                    result.success(true) 
                }
                "getInstalledApps" -> {
                    val apps = getInstalledApps()
                    result.success(apps)
                }
                "launchApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        launchApp(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_PACKAGE", "Package name is null", null)
                    }
                }
                "getAppSignature" -> {
                    val signature = getAppSignature()
                    result.success(signature)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getAppSignature(): String {
        try {
            val packageInfo = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.GET_SIGNING_CERTIFICATES)
            } else {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, android.content.pm.PackageManager.GET_SIGNATURES)
            }
            
            val signatures = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
                packageInfo.signingInfo.signingCertificateHistory
            } else {
                @Suppress("DEPRECATION")
                packageInfo.signatures
            }

            val md = java.security.MessageDigest.getInstance("SHA1")
            val digest = md.digest(signatures[0].toByteArray())
            return digest.joinToString(":") { "%02X".format(it) }
        } catch (e: Exception) {
            return "Error: ${e.message}"
        }
    }

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val intent = Intent(Intent.ACTION_MAIN, null)
        intent.addCategory(Intent.CATEGORY_LAUNCHER)
        val resolveInfos = pm.queryIntentActivities(intent, 0)
        
        val apps = mutableListOf<Map<String, Any>>()
        for (resolveInfo in resolveInfos) {
            val appInfo = mutableMapOf<String, Any>()
            appInfo["name"] = resolveInfo.loadLabel(pm).toString()
            appInfo["packageName"] = resolveInfo.activityInfo.packageName
            
            try {
                val iconDrawable = resolveInfo.loadIcon(pm)
                val bitmap = getBitmapFromDrawable(iconDrawable)
                val stream = ByteArrayOutputStream()
                // サイズを小さくするために圧縮率を調整し、必要に応じてリサイズすることも可能ですが、
                // 今回はそのままPNG変換します。
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                appInfo["icon"] = stream.toByteArray()
            } catch (e: Exception) {
                // アイコン取得に失敗した場合は無視（Flutter側でフォールバック表示）
            }

            apps.add(appInfo)
        }
        return apps
    }

    private fun getBitmapFromDrawable(drawable: Drawable): Bitmap {
        if (drawable is BitmapDrawable && drawable.bitmap != null) {
            return drawable.bitmap
        }
        val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 100
        val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 100
        
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        return bitmap
    }

    private fun launchApp(packageName: String) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        if (intent != null) {
            startActivity(intent)
        }
    }
}
