package com.kioskfront.kiosk_front

import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "byone/device"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "isAndroidTV" -> {

                    val pm = packageManager

                    val isTv =
                        pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ||
                                pm.hasSystemFeature(PackageManager.FEATURE_TELEVISION)

                    result.success(isTv)
                }

                // Dipakai tombol "LIVE": kirim app ke background TANPA menutupnya,
                // supaya Android TV Launcher (Netflix/YouTube/HDMI/dll) tampil,
                // dan app bisa dipanggil kembali lewat bringToForeground().
                "moveToBackground" -> {
                    moveTaskToBack(true)
                    result.success(true)
                }

                // Dipakai saat sesi berakhir/di-stop admin: paksa app kembali ke depan.
                // Catatan: sejak Android 10 ada pembatasan "start activity from background",
                // jadi ini best-effort dan mungkin tidak selalu berhasil tergantung OEM.
                "bringToForeground" -> {
                    val intent = Intent(this, MainActivity::class.java).apply {
                        flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                Intent.FLAG_ACTIVITY_NEW_TASK
                    }
                    startActivity(intent)
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}