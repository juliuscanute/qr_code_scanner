package net.touchcapture.qr.flutterqr

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.pm.PackageManager
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.Build
import android.os.Bundle
import android.view.View
import com.google.zxing.ResultPoint
import android.hardware.Camera.CameraInfo
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.BarcodeView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView

class QRView(private val registrar: PluginRegistry.Registrar, id: Int) :
        PlatformView,MethodChannel.MethodCallHandler {

    companion object {
        const val CAMERA_REQUEST_ID = 513469796
    }

    var barcodeView: BarcodeView? = null
    private val activity = registrar.activity()
    var cameraPermissionContinuation: Runnable? = null
    private var requestingPermission = false
    private var isTorchOn: Boolean = false
    val channel: MethodChannel

    init {
        registrar.addRequestPermissionsResultListener(CameraRequestPermissionsListener())
        channel = MethodChannel(registrar.messenger(), "net.touchcapture.qr.flutterqr/qrview_$id")
        channel.setMethodCallHandler(this)
        registrar.activity().application.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityPaused(p0: Activity?) {
                if (p0 == registrar.activity()) {
                    barcodeView?.pause()
                }
            }

            override fun onActivityResumed(p0: Activity?) {
                if (p0 == registrar.activity()) {
                    barcodeView?.resume()
                }
            }

            override fun onActivityStarted(p0: Activity?) {
            }

            override fun onActivityDestroyed(p0: Activity?) {
            }

            override fun onActivitySaveInstanceState(p0: Activity?, p1: Bundle?) {
            }

            override fun onActivityStopped(p0: Activity?) {
            }

            override fun onActivityCreated(p0: Activity?, p1: Bundle?) {
            }
        })
    }

    private fun flipCamera() {
        barcodeView?.pause()
        val settings = barcodeView?.cameraSettings

        if(settings?.requestedCameraId == CameraInfo.CAMERA_FACING_FRONT)
            settings.requestedCameraId = CameraInfo.CAMERA_FACING_BACK
        else
            settings?.requestedCameraId = CameraInfo.CAMERA_FACING_FRONT

        barcodeView?.cameraSettings = settings
        barcodeView?.resume()
    }

    private fun toggleFlash() {
        if (hasFlash()) {
            barcodeView?.setTorch(!isTorchOn)
            isTorchOn = !isTorchOn
        }

    }

    private fun pauseCamera() {
        if (barcodeView!!.isPreviewActive) {
            barcodeView?.pause()
        }
    }

    private fun resumeCamera() {
        if (!barcodeView!!.isPreviewActive) {
            barcodeView?.resume()
        }
    }

    private fun hasFlash(): Boolean {
        return registrar.activeContext().packageManager
                .hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
    }

    override fun getView(): View {
        return initBarCodeView()?.apply {
            resume()
        }!!
    }

    private fun initBarCodeView(): BarcodeView? {
        if (barcodeView == null) {
            barcodeView = BarcodeView(registrar.activity())
        }
        return barcodeView
    }

    private fun startScan(args: Map<String, Any>, result: MethodChannel.Result) {
        barcodeView?.pause()
        val settings = barcodeView?.cameraSettings
        settings?.requestedCameraId = if(args["cameraFacing"] as? Int == 1) CameraInfo
        .CAMERA_FACING_FRONT else CameraInfo.CAMERA_FACING_BACK
        barcodeView?.cameraSettings = settings
        barcodeView?.resume()

        checkAndRequestPermission(result){
            barcodeView?.decodeContinuous(
                object : BarcodeCallback {
                    override fun barcodeResult(result: BarcodeResult) {
                        channel.invokeMethod("onRecognizeQR", result.text)
                    }

                    override fun possibleResultPoints(resultPoints: List<ResultPoint>) {}
                }
            )
        }

    }

    private fun updateCameraSettings(cameraSettings: Map<String, Any>) {
        barcodeView?.pause()
        val settings = barcodeView?.cameraSettings

        settings?.requestedCameraId = if(cameraSettings["cameraFacing"] as? Int == 1) CameraInfo
        .CAMERA_FACING_FRONT else CameraInfo.CAMERA_FACING_BACK

        barcodeView?.cameraSettings = settings
        barcodeView?.resume()
    }

    override fun dispose() {
        barcodeView?.pause()
        barcodeView = null
    }

    private inner class CameraRequestPermissionsListener : PluginRegistry.RequestPermissionsResultListener {
        override fun onRequestPermissionsResult(id: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
            if (id == CAMERA_REQUEST_ID && grantResults[0] == PERMISSION_GRANTED) {
                cameraPermissionContinuation?.run()
                return true
            }
            return false
        }
    }

    private fun hasCameraPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                activity.checkSelfPermission(Manifest.permission.CAMERA) == PERMISSION_GRANTED
    }


    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when(call.method){
            "startScan" -> {
                if(call.arguments == null) return

                @Suppress("UNCHECKED_CAST")
                startScan(call.arguments as Map<String, Any>, result)
            }
            "updateSettings" -> {
                @Suppress("UNCHECKED_CAST")
                updateCameraSettings(call.arguments as Map<String, Any>)
            }
            "flipCamera" -> {
                flipCamera()
            }
            "toggleFlash" -> {
                toggleFlash()
            }
            "pauseCamera" -> {
                pauseCamera()
            }
            "resumeCamera" -> {
                resumeCamera()
            }
        }
    }

    private fun checkAndRequestPermission(result: MethodChannel.Result?, callback: (() -> Unit)? =
        null) {
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

            if(callback != null) callback()
        }

        requestingPermission = false
        if (hasCameraPermission()) {
            cameraPermissionContinuation?.run()
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                requestingPermission = true
                registrar
                        .activity()
                        .requestPermissions(
                                arrayOf(Manifest.permission.CAMERA),
                                CAMERA_REQUEST_ID)
            }
        }
    }

}
