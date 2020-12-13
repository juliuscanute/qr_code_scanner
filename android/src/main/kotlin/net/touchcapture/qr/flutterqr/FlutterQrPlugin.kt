package net.touchcapture.qr.flutterqr

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry


class FlutterQrPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    var cameraPermissionContinuation: Runnable? = null
    var requestingPermission = false
//    private var activity: Activity? = null

//    /** Plugin registration embedding v1 */
//    companion object {
//        @JvmStatic
//        fun registerWith(registrar: Registrar) {
//            FlutterQrPlugin().onAttachedToEngine(registrar)
//        }
//    }

    /** Plugin registration embedding v2 */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngines(flutterPluginBinding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    // TODO: Fix v1 embedding for Flutter < 1.12 support
    /** Plugin start for both embedding v1 & v2 */
    private fun onAttachedToEngines(binding: FlutterPlugin.FlutterPluginBinding) {
        binding.platformViewRegistry
                .registerViewFactory(
                        "net.touchcapture.qr.flutterqr/qrview", QRViewFactory(binding.binaryMessenger))
    }

//    private fun onAttachedToEngine(registrar: Registrar) {
//        activity = registrar.activity()
//        registrar.addRequestPermissionsResultListener(CameraRequestPermissionsListener())
//        checkAndRequestPermission(null)
//        registrar
//                .platformViewRegistry()
//                .registerViewFactory(
//                        "net.touchcapture.qr.flutterqr/qrview", QRViewFactory(registrar))
//    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "checkAndRequestPermission" -> checkAndRequestPermission(result)
        }
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        Shared.activityPluginBinding = activityPluginBinding
        Shared.activity = activityPluginBinding.activity
        activityPluginBinding.addRequestPermissionsResultListener(CameraRequestPermissionsListener())
        checkAndRequestPermission(null)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Shared.activityPluginBinding = null
        Shared.activity = null
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        Shared.activityPluginBinding = activityPluginBinding
        Shared.activity = activityPluginBinding.activity
    }

    override fun onDetachedFromActivity() {
        Shared.activityPluginBinding = null
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
            result?.error("cameraPermission", "Camera permission request ongoing", null);
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
