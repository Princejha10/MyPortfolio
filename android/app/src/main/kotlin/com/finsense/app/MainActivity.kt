package com.finsense.app

import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.provider.Settings
import android.util.Base64
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.finsense.ai/notifications"
    private val EVENT_CHANNEL = "com.finsense.ai/notification_stream"

    private val bankingPackages = listOf(
        "com.google.android.apps.nbu.paisa.user", // Google Pay
        "com.phonepe.app",                       // PhonePe
        "net.one97.paytm",                       // Paytm
        "in.org.npci.upiapp",                    // BHIM
        "com.amazon.mShop.android.shopping",     // Amazon Pay
        "com.whatsapp",                          // WhatsApp Pay
        "com.sbi.upi",                           // SBI Pay
        "com.sbi.SBIOnyx",                       // SBI Quick
        "com.sbi.yono",                          // SBI Yono
        "com.snapwork.hdfc",                     // HDFC MobileBanking
        "com.hdfcbank.smartbuy",                 // HDFC PayZapp
        "com.csam.icici.bank.imobile",           // ICICI iMobile
        "com.axis.mobile",                       // Axis Bank Mobile
        "com.msf.kbank.mobile",                  // Kotak MobileBanking
        "com.pnb.mbanking",                      // PNB ONE
        "com.canarabank.onetouch",               // Canara ai1
        "com.bobworld.mobile",                   // BoB World
        "com.unionbank.online",                  // Vyom Union Bank
        "com.myairtelapp"                        // Airtel Thanks / Payments Bank
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. MethodChannel for administrative capabilities
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkPermission" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "getPackageName" -> {
                    result.success(packageName)
                }
                "requestPermission" -> {
                    try {
                        val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "startListening" -> {
                    result.success(true)
                }
                "stopListening" -> {
                    result.success(true)
                }
                "getInstalledBankingApps" -> {
                    val installedAppsList = mutableListOf<Map<String, Any>>()
                    val pm = packageManager
                    for (pkg in bankingPackages) {
                        try {
                            val appInfo = pm.getApplicationInfo(pkg, 0)
                            val appLabel = pm.getApplicationLabel(appInfo).toString()
                            val iconDrawable = pm.getApplicationIcon(appInfo)
                            val base64Icon = drawableToBase64(iconDrawable)
                            installedAppsList.add(mapOf(
                                "name" to appLabel,
                                "package" to pkg,
                                "icon" to base64Icon
                            ))
                        } catch (e: PackageManager.NameNotFoundException) {
                            // Package not installed, ignore
                        }
                    }
                    result.success(installedAppsList)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // 2. EventChannel for streaming notifications in real-time
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    MyNotificationListenerService.notificationListener = { message, packageName ->
                        runOnUiThread {
                            events?.success(mapOf(
                                "message" to message,
                                "packageName" to packageName
                            ))
                        }
                    }
                }

                override fun onCancel(arguments: Any?) {
                    MyNotificationListenerService.notificationListener = null
                }
            }
        )
    }

    private fun drawableToBase64(drawable: Drawable): String {
        val bitmap = if (drawable.intrinsicWidth <= 0 || drawable.intrinsicHeight <= 0) {
            Bitmap.createBitmap(1, 1, Bitmap.Config.ARGB_8888)
        } else {
            Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
        }
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)

        val outputStream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, outputStream)
        val bytes = outputStream.toByteArray()
        return Base64.encodeToString(bytes, Base64.NO_WRAP)
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val packageNameVal = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (flat != null) {
            val names = flat.split(":")
            for (name in names) {
                if (name.contains(packageNameVal)) {
                    return true
                }
            }
        }
        return false
    }
}
