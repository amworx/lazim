package com.amworx.lazim

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Hosts the self-update bridge.
 *
 * Android will not let an app install a package silently. The flow is:
 *
 *   1. `canInstallPackages` — is this app already allowed to install packages?
 *   2. `requestInstallPermission` — if not, open the system screen where the
 *      user grants "Install unknown apps" for Lazim. This is a one-time,
 *      per-app grant the user must give deliberately; there is no way around it
 *      and no permission that can be declared to skip it.
 *   3. `installApk` — hand the downloaded APK to the system installer via a
 *      FileProvider content URI. The user sees the normal Android install
 *      prompt and confirms.
 *
 * The APK must be signed with the same key as the installed app or Android
 * rejects the update. Debug builds are signed with the debug key, so a debug
 * install can only be updated by another debug build.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "lazim/updater"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "canInstallPackages" -> result.success(canInstallPackages())

                    "requestInstallPermission" -> {
                        if (canInstallPackages()) {
                            result.success(true)
                        } else {
                            openInstallPermissionSettings()
                            // The user decides on the system screen; the Dart
                            // side re-checks after the app resumes.
                            result.success(false)
                        }
                    }

                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_args", "Missing APK path", null)
                            return@setMethodCallHandler
                        }
                        try {
                            installApk(path)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("install_failed", e.message ?: "Install failed", null)
                        }
                    }

                    // Attachment viewing. The Dart side reads the file bytes out
                    // of Firestore and hands them here; this writes them to a
                    // cache file and opens it with whatever app handles the MIME
                    // type. Needed because a Firestore blob has no URL a viewer
                    // could open.
                    "openAttachment" -> {
                        val name = call.argument<String>("name")
                        val mime = call.argument<String>("mimeType")
                        val bytes = call.argument<ByteArray>("bytes")
                        if (name == null || bytes == null) {
                            result.error("bad_args", "Missing attachment name or bytes", null)
                            return@setMethodCallHandler
                        }
                        try {
                            openAttachment(name, mime ?: "application/octet-stream", bytes)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("open_failed", e.message ?: "Open failed", null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun canInstallPackages(): Boolean {
        // Below Android 8 there is no per-app install permission.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
        return packageManager.canRequestPackageInstalls()
    }

    private fun openInstallPermissionSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    /**
     * Writes attachment bytes to a cache file and opens it with the system
     * viewer. The file must live under the `attachments/` cache path declared in
     * updater_paths.xml, or FileProvider.getUriForFile throws.
     */
    private fun openAttachment(name: String, mimeType: String, bytes: ByteArray) {
        // Strip any path separators a weird filename might carry.
        val safeName = name.substringAfterLast('/').substringAfterLast('\\')
            .ifBlank { "attachment" }
        val dir = File(cacheDir, "attachments")
        if (!dir.exists()) dir.mkdirs()

        val target = File(dir, safeName)
        target.writeBytes(bytes)

        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.updater",
            target,
        )

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun installApk(path: String) {
        val file = File(path)
        if (!file.exists()) throw IllegalStateException("APK not found at $path")

        // FileProvider hands the installer a content:// URI. A raw file:// URI
        // throws FileUriExposedException on Android 7+.
        val uri: Uri = FileProvider.getUriForFile(
            this,
            "$packageName.updater",
            file,
        )

        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
