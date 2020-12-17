package net.touchcapture.qr.flutterqr

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformViewRegistry


class FlutterQrPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    var cameraPermissionContinuation: Runnable? = null
    var requestingPermission = false

    /** Plugin registration embedding v1 */
    companion object {
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            FlutterQrPlugin().onAttachedToV1(registrar)
        }
    }

    private fun onAttachedToV1(registrar: PluginRegistry.Registrar) {
        registrar.addRequestPermissionsResultListener(CameraRequestPermissionsListener())
        checkAndRequestPermission(null)
        onAttachedToEngines(registrar.platformViewRegistry(), registrar.messenger(), registrar.activity())
    }

    /** Plugin registration embedding v2 */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngines(flutterPluginBinding.platformViewRegistry, flutterPluginBinding.binaryMessenger, Shared.activity)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    /** Plugin start for both embedding v1 & v2 */
    private fun onAttachedToEngines(platformViewRegistry: PlatformViewRegistry, messenger: BinaryMessenger, activity: Activity?) {
        if (activity != null) {
            Shared.activity = activity
        }
        platformViewRegistry
                .registerViewFactory(
                        "net.touchcapture.qr.flutterqr/qrview", QRViewFactory(messenger))
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkAndRequestPermission" -> checkAndRequestPermission(result)
        }
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        Shared.activity = activityPluginBinding.activity
        activityPluginBinding.addRequestPermissionsResultListener(CameraRequestPermissionsListener())
        checkAndRequestPermission(null)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Shared.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        Shared.activity = activityPluginBinding.activity
    }

    override fun onDetachedFromActivity() {
        Shared.activity = null
    }

    private inner class CameraRequestPermissionsListener : PluginRegistry.RequestPermissionsResultListener {
        override fun onRequestPermissionsResult(id: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
            if (id == QRView.CAMERA_REQUEST_ID && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                cameraPermissionContinuation?.run()
                return true
            }
            return false
        }
    }

    private fun hasCameraPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                Shared.activity?.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkAndRequestPermission(result: Result?) {
        if (cameraPermissionContinuation != null) {
            result?.error("cameraPermission", "Camera permission request ongoing", null)
        }

        cameraPermissionContinuation = Runnable {
            cameraPermissionContinuation = null
            if (!hasCameraPermission()) {
                result?.error(
                        "cameraPermission", "MediaRecorderCamera permission not granted", null)
                return@Runnable
            }
        }

        requestingPermission = false
        if (hasCameraPermission()) {
            cameraPermissionContinuation?.run()
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestingPermission = true
                Shared.activity?.requestPermissions(
                        arrayOf(Manifest.permission.CAMERA),
                        QRView.CAMERA_REQUEST_ID)
            }
        }
    }
}
