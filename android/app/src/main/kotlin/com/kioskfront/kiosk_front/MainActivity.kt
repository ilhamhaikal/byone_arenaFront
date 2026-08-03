package com.kioskfront.kiosk_front

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
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

                // ── Overlay LIVE/waktu/warning (docs/jawaban.md) ──────────
                // Dipakai HANYA saat state Active: badge kecil digambar via
                // WindowManager oleh OverlayService, MainActivity di-
                // background-kan (moveTaskToBack) supaya Game/YouTube/
                // Launcher yang sedang dipakai pemain kembali terlihat.

                "hasOverlayPermission" -> result.success(canDrawOverlays())

                "requestOverlayPermission" -> {
                    if (!canDrawOverlays()) {
                        try {
                            startActivity(
                                Intent(
                                    Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                                    Uri.parse("package:$packageName")
                                )
                            )
                        } catch (e: Exception) {
                            // Sebagian Android TV box tidak menyediakan layar
                            // Settings ini — biarkan gagal secara senyap,
                            // caller (Dart) akan fallback ke tampilan blank.
                        }
                    }
                    result.success(canDrawOverlays())
                }

                "startOverlay" -> {
                    if (!canDrawOverlays()) {
                        result.success(false)
                    } else {
                        sendOverlayIntent(call.arguments, startForeground = true)
                        moveTaskToBack(true)
                        result.success(true)
                    }
                }

                "updateOverlay" -> {
                    sendOverlayIntent(call.arguments, startForeground = true)
                    result.success(true)
                }

                "stopOverlay" -> {
                    val intent = Intent(this, OverlayService::class.java).apply {
                        action = OverlayService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(true)
                }

                "bringToFront" -> {
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

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun sendOverlayIntent(arguments: Any?, startForeground: Boolean) {
        val args = arguments as? Map<*, *>
        val intent = Intent(this, OverlayService::class.java).apply {
            putExtra(OverlayService.EXTRA_TITLE, args?.get("title") as? String ?: "LIVE")
            putExtra(OverlayService.EXTRA_SUBTITLE, args?.get("subtitle") as? String ?: "")
            putExtra(OverlayService.EXTRA_VARIANT, args?.get("variant") as? String ?: "live")
        }
        if (startForeground && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}