package com.antigravity.pdfreader.pdf_tools

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.antigravity.pdfreader/intent"
    private var pendingPdfData: Map<String, Any?>? = null
    private var methodChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingPdfData = processIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val data = processIntent(intent)
        if (data != null) {
            val channel = methodChannel
            if (channel != null) {
                channel.invokeMethod("onPdfOpened", data)
            } else {
                pendingPdfData = data
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialPdf" -> {
                    val data = pendingPdfData
                    pendingPdfData = null
                    result.success(data)
                }
                else -> result.notImplemented()
            }
        }

        // If an intent was already pending when Flutter engine configured, send it
        pendingPdfData?.let { data ->
            methodChannel?.invokeMethod("onPdfOpened", data)
        }
    }

    private fun processIntent(intent: Intent?): Map<String, Any?>? {
        if (intent == null) return null
        val action = intent.action ?: return null

        val uri: Uri? = when (action) {
            Intent.ACTION_VIEW, Intent.ACTION_EDIT -> intent.data
            Intent.ACTION_SEND -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
                } else {
                    @Suppress("DEPRECATION")
                    intent.getParcelableExtra<Uri>(Intent.EXTRA_STREAM)
                }
            }
            else -> intent.data
        }

        return uri?.let { extractPdfData(it) }
    }

    private fun extractPdfData(uri: Uri): Map<String, Any?>? {
        try {
            var fileName = "Document.pdf"
            if (uri.scheme == "content") {
                val cursor = contentResolver.query(uri, null, null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val nameIndex = it.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                        if (nameIndex != -1) {
                            val name = it.getString(nameIndex)
                            if (!name.isNullOrBlank()) {
                                fileName = name
                            }
                        }
                    }
                }
            } else if (uri.scheme == "file") {
                uri.lastPathSegment?.let { seg ->
                    if (seg.isNotBlank()) fileName = seg
                }
            }

            if (!fileName.endsWith(".pdf", ignoreCase = true)) {
                fileName = "$fileName.pdf"
            }

            val inputStream = contentResolver.openInputStream(uri) ?: return null
            val bytes = inputStream.use { it.readBytes() }
            if (bytes.isEmpty()) return null

            // Write to app cache so local path is also available for saving/referencing
            val cacheFile = File(cacheDir, "opened_${System.currentTimeMillis()}_$fileName")
            cacheFile.writeBytes(bytes)

            return mapOf(
                "name" to fileName,
                "path" to cacheFile.absolutePath,
                "bytes" to bytes
            )
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }
}
