package com.mleysoft.aidat

import android.Manifest
import android.content.pm.PackageManager
import android.os.Build
import android.graphics.Color
import android.net.Uri
import androidx.browser.customtabs.CustomTabsIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.mleysoft.aidat/notifications"
    private val requestCode = 4901
    private val legalChannelName = "com.mleysoft.aidat/legal_browser"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else {
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), requestCode)
                            result.success(true)
                        }
                    } else result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, legalChannelName).setMethodCallHandler { call, result ->
            if (call.method == "open") {
                val url = call.argument<String>("url")
                if (url.isNullOrBlank()) { result.error("INVALID_URL", "URL boş", null); return@setMethodCallHandler }
                try {
                    val metrics = resources.displayMetrics
                    val initialHeight = (metrics.heightPixels * 0.88).toInt()
                    val builder = CustomTabsIntent.Builder()
                        .setShowTitle(true)
                        .setToolbarColor(Color.WHITE)
                        .setNavigationBarColor(Color.WHITE)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        builder.setInitialActivityHeightPx(initialHeight)
                    }
                    builder.build().launchUrl(this, Uri.parse(url))
                    result.success(true)
                } catch (e: Exception) { result.error("OPEN_FAILED", e.message, null) }
            } else result.notImplemented()
        }

    }
}
