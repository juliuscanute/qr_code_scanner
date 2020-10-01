package net.touchcapture.qr.flutterqr

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar

class FlutterQrPlugin : MethodCallHandler {
    private lateinit var applicationContext: Context
    private lateinit var channel: MethodChannel
    private val listener = CameraRequestPermissionsListener()

    private fun onAttachedToEngine(applicationContext: Context, messenger: BinaryMessenger) {
        this.applicationContext = applicationContext
        channel = MethodChannel(messenger, "net.touchcapture.qr.flutterqr/qrview")
        channel.setMethodCallHandler(this)
    }

    companion object {
        lateinit var registrar: Registrar
        private var activity: Activity? = null

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val instance = FlutterQrPlugin()
            registrar
                    .platformViewRegistry()
                    .registerViewFactory(
                            "net.touchcapture.qr.flutterqr/qrview", QRViewFactory(registrar))
            this.registrar = registrar
            this.activity = registrar.activity()
            instance.onAttachedToEngine(registrar.context(), registrar.messenger())
            registrar.addRequestPermissionsResultListener(instance.listener)
        }
    }

    private inner class CameraRequestPermissionsListener : PluginRegistry.RequestPermissionsResultListener {
        var result: Result? = null

        override fun onRequestPermissionsResult(id: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
            if (result == null) {
                return true
            }
            if (id == QRView.CAMERA_REQUEST_ID && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                result?.success(true)
                result = null
                return true
            }
            result?.success(false)
            result = null
            return false
        }
    }

    private fun requestPermissions(result: Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                activity?.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
            result.success(true)
        } else {
            listener.result = result

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                activity?.requestPermissions(
                        arrayOf(Manifest.permission.CAMERA),
                        QRView.CAMERA_REQUEST_ID)
            } else {
                result.success(false)
            }
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when {
            call.method == "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            call.method == "requestPermissions" -> requestPermissions(result)
            else -> result.notImplemented()
        }
    }
}
