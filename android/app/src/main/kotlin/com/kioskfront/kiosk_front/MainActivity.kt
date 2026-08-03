package com.kioskfront.kiosk_front

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

                else -> result.notImplemented()
            }
        }
    }
}