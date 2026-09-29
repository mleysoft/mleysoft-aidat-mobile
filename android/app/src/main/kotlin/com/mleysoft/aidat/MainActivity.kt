package com.mleysoft.aidat

import android.Manifest
import android.content.pm.PackageManager
import android.content.Intent
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
    private val sharedFileChannelName = "com.mleysoft.aidat/shared_file"
    private var sharedFileChannel: MethodChannel? = null
    private var pendingSharedFile: String? = null

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
        sharedFileChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, sharedFileChannelName)
        sharedFileChannel!!.setMethodCallHandler { call, result ->
            when(call.method){
                "getPendingSharedFile" -> { val p=pendingSharedFile; pendingSharedFile=null; result.success(p) }
                else -> result.notImplemented()
            }
        }
        handleSharedIntent(intent, false)

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

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSharedIntent(intent, true)
    }

    private fun handleSharedIntent(intent: Intent?, notifyFlutter: Boolean) {
        if (intent == null) return
        val uri: Uri? = when (intent.action) {
            Intent.ACTION_SEND -> intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
            Intent.ACTION_VIEW -> intent.data
            else -> null
        }
        if (uri == null) return
        try {
            val displayName = uri.lastPathSegment?.substringAfterLast('/') ?: "banka_hareketleri.xlsx"
            val safeName = displayName.replace(Regex("[^A-Za-z0-9._-]"), "_")
            val outFile = java.io.File(cacheDir, "shared_${System.currentTimeMillis()}_$safeName")
            contentResolver.openInputStream(uri)?.use { input -> outFile.outputStream().use { output -> input.copyTo(output) } } ?: return
            pendingSharedFile = outFile.absolutePath
            if (notifyFlutter) sharedFileChannel?.invokeMethod("sharedFileReceived", pendingSharedFile)
        } catch (_: Exception) { }
    }

}
