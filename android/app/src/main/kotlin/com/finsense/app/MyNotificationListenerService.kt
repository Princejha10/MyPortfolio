package com.finsense.app

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

class MyNotificationListenerService : NotificationListenerService() {
    companion object {
        private var instance: MyNotificationListenerService? = null
        
        // Static callback registered by MainActivity to pipe events into the EventChannel
        var notificationListener: ((message: String, packageName: String) -> Unit)? = null
        
        fun isServiceRunning(): Boolean {
            return instance != null
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: ""
        
        // 1. Retrieve SharedPreferences configured by the Flutter client
        val context = applicationContext
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // 2. Check if global reader is enabled
        val isReaderEnabled = prefs.getBoolean("flutter.isNotificationReaderEnabled", false)
        if (!isReaderEnabled) return

        // 3. Check if package name is in the user's selected list
        val csv = prefs.getString("flutter.enabledPackagesCsv", "") ?: ""
        if (csv.isNotEmpty()) {
            val enabledList = csv.split(",")
            if (!enabledList.contains(packageName)) {
                return // Discard notifications from disabled apps immediately at native step
            }
        } else {
            // Default list if user hasn't customized it yet
            val standardApps = listOf(
                "com.google.android.apps.nbu.paisa.user", "com.phonepe.app", "net.one97.paytm",
                "in.org.npci.upiapp", "com.amazon.mShop.android.shopping", "com.whatsapp",
                "com.sbi.upi", "com.sbi.SBIOnyx", "com.sbi.yono", "com.snapwork.hdfc",
                "com.hdfcbank.smartbuy", "com.csam.icici.bank.imobile", "com.axis.mobile",
                "com.msf.kbank.mobile", "com.pnb.mbanking", "com.canarabank.onetouch",
                "com.bobworld.mobile", "com.unionbank.online", "com.myairtelapp"
            )
            if (!standardApps.contains(packageName)) {
                return
            }
        }

        val extras = sbn.notification?.extras ?: return
        
        // Retrieve common text values from android.notification payload
        val title = extras.getString("android.title") ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""

        // Combine fields to ensure regex filters catch details regardless of layout
        var fullMessage = ""
        if (text.isNotEmpty()) {
            fullMessage = text
        } else if (bigText.isNotEmpty()) {
            fullMessage = bigText
        } else if (title.isNotEmpty()) {
            fullMessage = title
        }

        if (fullMessage.isNotEmpty()) {
            // Forward filtered payload to MainActivity EventChannel stream
            notificationListener?.invoke(fullMessage, packageName)
        }
    }
}
