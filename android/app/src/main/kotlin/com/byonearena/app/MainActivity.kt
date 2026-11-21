package com.byonearena.app

import android.app.ActivityManager
import android.content.Context
import android.content.ComponentName
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.input.InputManager
import android.media.tv.TvContract
import android.media.tv.TvInputInfo
import android.media.tv.TvInputManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.provider.Settings
import android.view.KeyEvent
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.flame_engine.gamepads_android.GamepadsCompatibleActivity

class MainActivity : FlutterActivity(), GamepadsCompatibleActivity {

    // ── Controller (plugin gamepads) ───────────────────────────────────
    private var keyListener: ((KeyEvent) -> Boolean)? = null
    private var motionListener: ((MotionEvent) -> Boolean)? = null

    override fun dispatchGenericMotionEvent(motionEvent: MotionEvent): Boolean {
        if (motionListener?.invoke(motionEvent) == true) return true
        return super.dispatchGenericMotionEvent(motionEvent)
    }

    override fun dispatchKeyEvent(keyEvent: KeyEvent): Boolean {
        if (keyListener?.invoke(keyEvent) == true) return true
        return super.dispatchKeyEvent(keyEvent)
    }

    override fun registerInputDeviceListener(
        listener: InputManager.InputDeviceListener,
        handler: Handler?
    ) {
        val inputManager = getSystemService(INPUT_SERVICE) as InputManager
        inputManager.registerInputDeviceListener(listener, null)
    }

    override fun registerKeyEventHandler(handler: (KeyEvent) -> Boolean) {
        keyListener = handler
    }

    override fun registerMotionEventHandler(handler: (MotionEvent) -> Boolean) {
        motionListener = handler
    }

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
                        // Pindah ke input HDMI konsol (jika tersedia) supaya
                        // pemain langsung melihat sinyal PlayStation, bukan
                        // launcher/game sebelumnya.
                        switchToTvInput(
                            (call.arguments as? Map<*, *>)?.get("consoleType") as? String
                        )
                        moveTaskToBack(true)
                        result.success(true)
                    }
                }

                "switchToTvInput" -> {
                    result.success(
                        switchToTvInput(call.arguments as? String)
                    )
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
                    // Bawa Activity ini kembali ke depan supaya layar fullscreen
                    // berikutnya (overtime/idle/maintenance) langsung terlihat.
                    // Pendekatan paling andal untuk root Activity yang sebelumnya
                    // di-background via moveTaskToBack(true): pindahkan TASK ke
                    // depan lewat ActivityManager (perlu izin REORDER_TASKS).
                    try {
                        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
                        am.moveTaskToFront(taskId, ActivityManager.MOVE_TASK_WITH_HOME)
                    } catch (e: Exception) {
                        // fallback di bawah
                    }
                    try {
                        val intent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or
                                Intent.FLAG_ACTIVITY_NEW_TASK or
                                Intent.FLAG_ACTIVITY_SINGLE_TOP
                        }
                        startActivity(intent)
                    } catch (e: Exception) {
                        // abaikan
                    }
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    /// Pindah ke input HDMI konsol. Di TV Xiaomi/MediaTek input picker
    /// memakai activity LiveTV dengan URI passthrough TvInput.
    /// Mengembalikan true bila activity input berhasil dijalankan.
    private fun switchToTvInput(consoleType: String?): Boolean {
        return try {
            val manager = getSystemService(Context.TV_INPUT_SERVICE) as TvInputManager
            val hdmiInputs = manager.tvInputList.filter { it.type == TvInputInfo.TYPE_HDMI }
            if (hdmiInputs.isEmpty()) return false

            fun labelOf(info: TvInputInfo): String =
                info.loadLabel(this).toString()

            val preferred = hdmiInputs.firstOrNull { info ->
                val label = labelOf(info)
                label.contains("PlayStation", ignoreCase = true) ||
                    label.contains("PS4", ignoreCase = true) ||
                    label.contains("PS5", ignoreCase = true) ||
                    (!consoleType.isNullOrBlank() &&
                        label.contains(consoleType, ignoreCase = true))
            } ?: hdmiInputs.first()

            val uri = TvContract.buildChannelUriForPassthroughInput(preferred.id)
            val intent = Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                setComponent(
                    ComponentName(
                        "com.mitv.livetv",
                        "com.mitv.livetv.tv.MainActivity"
                    )
                )
            }
            try {
                startActivity(intent)
            } catch (e: Exception) {
                // Vendor activity tidak tersedia/terproteksi — coba handler
                // TV input standar lewat implicit intent.
                intent.component = null
                startActivity(intent)
            }
            true
        } catch (e: Exception) {
            false
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
            putExtra(OverlayService.EXTRA_BADGE_VISIBLE, args?.get("badgeVisible") as? Boolean ?: false)
            putExtra(OverlayService.EXTRA_TITLE, args?.get("badgeTitle") as? String ?: "LIVE")
            putExtra(OverlayService.EXTRA_SUBTITLE, args?.get("badgeSubtitle") as? String ?: "")
            putExtra(OverlayService.EXTRA_VARIANT, args?.get("badgeVariant") as? String ?: "live")
            putExtra(OverlayService.EXTRA_NOTIF_TITLE, args?.get("notifTitle") as? String ?: "")
            putExtra(OverlayService.EXTRA_NOTIF_MESSAGE, args?.get("notifMessage") as? String ?: "")
        }
        if (startForeground && Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}