package com.kioskfront.kiosk_front

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager

/**
 * Auto-launch aplikasi saat perangkat TV selesai boot (doc §5: Boot mechanism).
 *
 * Pengecekan "apakah ini Android TV" dilakukan di level device/hardware
 * (FEATURE_LEANBACK / FEATURE_TELEVISION), BUKAN berdasarkan role user,
 * supaya perilaku ini tidak memengaruhi HP admin/kasir yang memakai APK
 * yang sama.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        val pm = context.packageManager
        val isTv =
            pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
                    pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION)

        if (!isTv) return

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        context.startActivity(launchIntent)
    }
}
