package com.kioskfront.kiosk_front

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Foreground Service yang menggambar badge kecil ("LIVE" + sisa waktu /
 * warning) lewat WindowManager (TYPE_APPLICATION_OVERLAY), TERPISAH dari
 * FlutterActivity/MainActivity.
 *
 * Dipakai HANYA saat state Client == Active (docs/jawaban.md): pada state
 * ini MainActivity di-background-kan (moveTaskToBack) supaya tampilan
 * Game/YouTube/Launcher yang sedang dipakai pemain kembali terlihat & bisa
 * disentuh/di-remote, sementara Service ini (independen dari lifecycle
 * Activity) tetap menggambar info sesi di atasnya.
 *
 * Efek samping yang disengaja: karena Service ini foreground (proses sama
 * dengan MainActivity), OS tidak akan mem-prioritaskan-rendah proses App
 * walau Activity-nya sedang di-background — jadi Dart isolate/timer di
 * Flutter tetap jalan normal untuk terus mengirim update ke overlay ini.
 */
class OverlayService : Service() {

    companion object {
        const val ACTION_STOP = "com.kioskfront.kiosk_front.action.OVERLAY_STOP"
        const val EXTRA_TITLE = "title"
        const val EXTRA_SUBTITLE = "subtitle"
        const val EXTRA_VARIANT = "variant" // "live" | "warning" | "danger"

        private const val NOTIF_CHANNEL_ID = "byone_overlay_channel"
        private const val NOTIF_ID = 5501
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var titleView: TextView? = null
    private var subtitleView: TextView? = null
    private var dotView: View? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startForeground(NOTIF_ID, buildNotification())
        addOverlayView()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "LIVE"
        val subtitle = intent?.getStringExtra(EXTRA_SUBTITLE) ?: ""
        val variant = intent?.getStringExtra(EXTRA_VARIANT) ?: "live"
        updateContent(title, subtitle, variant)

        return START_STICKY
    }

    override fun onDestroy() {
        removeOverlayView()
        super.onDestroy()
    }

    private fun buildNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(NOTIF_CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    NOTIF_CHANNEL_ID,
                    "Byone Arena - Info Sesi",
                    NotificationManager.IMPORTANCE_MIN
                ).apply {
                    description = "Notifikasi latar belakang untuk overlay LIVE/sisa waktu sesi"
                    setShowBadge(false)
                }
                manager.createNotificationChannel(channel)
            }
            return Notification.Builder(this, NOTIF_CHANNEL_ID)
                .setContentTitle("Byone Arena")
                .setContentText("Sesi sedang berjalan")
                .setSmallIcon(android.R.drawable.presence_online)
                .setOngoing(true)
                .build()
        }

        @Suppress("DEPRECATION")
        return Notification.Builder(this)
            .setContentTitle("Byone Arena")
            .setContentText("Sesi sedang berjalan")
            .setSmallIcon(android.R.drawable.presence_online)
            .setOngoing(true)
            .build()
    }

    private fun addOverlayView() {
        if (overlayView != null) return

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val overlayType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            overlayType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.END
            x = 24
            y = 24
        }

        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(28, 18, 28, 18)
            background = pillDrawable(Color.parseColor("#CC1B1D3B"))
        }

        val dot = View(this).apply {
            layoutParams = LinearLayout.LayoutParams(18, 18).apply {
                marginEnd = 16
            }
            background = ovalDrawable(Color.parseColor("#22C55E"))
        }

        val textContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
        }

        val title = TextView(this).apply {
            setTextColor(Color.WHITE)
            textSize = 13f
            setTypeface(typeface, Typeface.BOLD)
            text = "LIVE"
        }

        val subtitle = TextView(this).apply {
            setTextColor(Color.parseColor("#C7CBEF"))
            textSize = 11f
            text = ""
            visibility = View.GONE
        }

        textContainer.addView(title)
        textContainer.addView(subtitle)
        container.addView(dot)
        container.addView(textContainer)

        windowManager?.addView(container, params)

        overlayView = container
        titleView = title
        subtitleView = subtitle
        dotView = dot
    }

    private fun pillDrawable(color: Int): GradientDrawable = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = 40f
        setColor(color)
    }

    private fun ovalDrawable(color: Int): GradientDrawable = GradientDrawable().apply {
        shape = GradientDrawable.OVAL
        setColor(color)
    }

    private fun updateContent(title: String, subtitle: String, variant: String) {
        if (overlayView == null) addOverlayView()

        titleView?.text = title
        subtitleView?.text = subtitle
        subtitleView?.visibility = if (subtitle.isEmpty()) View.GONE else View.VISIBLE

        val color = when (variant) {
            "danger" -> Color.parseColor("#EF4444")
            "warning" -> Color.parseColor("#F59E0B")
            else -> Color.parseColor("#22C55E")
        }
        dotView?.background = ovalDrawable(color)
    }

    private fun removeOverlayView() {
        val view = overlayView ?: return
        try {
            windowManager?.removeView(view)
        } catch (e: IllegalArgumentException) {
            // View sudah tidak ter-attach ke WindowManager — aman diabaikan.
        }
        overlayView = null
        titleView = null
        subtitleView = null
        dotView = null
    }
}
