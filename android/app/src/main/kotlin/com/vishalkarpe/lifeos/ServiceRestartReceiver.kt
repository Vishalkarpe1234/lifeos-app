package com.vishalkarpe.lifeos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * Restarts the VK OS background service (call alerts + live location) whenever:
 *  - device boots
 *  - screen turns on
 *  - user unlocks the phone
 *
 * This ensures call notifications and location tracking resume automatically even
 * if Android killed the service under memory pressure or the user swiped the app.
 */
class ServiceRestartReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Only restart if the user has already logged in (service was configured).
        // flutter_background_service writes autoStart config to SharedPreferences.
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val configured = prefs.all.keys.any { it.contains("background_service") || it.contains("bg_service") }
        if (!configured) return

        try {
            @Suppress("UNCHECKED_CAST")
            val serviceClass = Class.forName("id.flutter.flutter_background_service.BackgroundService")
            val serviceIntent = Intent(context, serviceClass)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        } catch (_: Exception) {}
    }
}
