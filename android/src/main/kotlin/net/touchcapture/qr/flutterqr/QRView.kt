package net.touchcapture.qr.flutterqr

import android.Manifest
import android.R
import android.app.Activity
import android.app.AlertDialog
import android.app.Application
import android.content.pm.PackageManager
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.hardware.Camera.CameraInfo
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import com.google.zxing.BarcodeFormat
import com.google.zxing.ResultPoint
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.BarcodeView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView

class QRView(private val registrar: PluginRegistry.Registrar, id: Int) :
        PlatformView, MethodChannel.MethodCallHandler {


    companion object {
        const val CAMERA_REQUEST_ID = 513469796
    }

    val QRCodeTypes = mapOf(
            0 to BarcodeFormat.AZTEC,
            1 to BarcodeFormat.CODE_128,
            2 to BarcodeFormat.CODE_39,
            3 to BarcodeFormat.CODE_93,
            4 to BarcodeFormat.DATA_MATRIX,
            5 to BarcodeFormat.EAN_13,
            6 to BarcodeFormat.EAN_8,
            7 to BarcodeFormat.ITF,
            8 to BarcodeFormat.PDF_417,
            9 to BarcodeFormat.QR_CODE,
            10 to BarcodeFormat.UPC_E
    )
    var barcodeView: BarcodeView? = null
    var allowedBarcodeTypes = mutableListOf<BarcodeFormat>()
    private val activity = registrar.activity()
    private var isTorchOn: Boolean = false
    val channel: MethodChannel

    init {
        registrar.addRequestPermissionsResultListener(CameraRequestPermissionsListener())
        channel = MethodChannel(registrar.messenger(), "net.touchcapture.qr.flutterqr/qrview_$id")
        channel.setMethodCallHandler(this)
        checkAndRequestPermission()
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

    private fun flipCamera(result: MethodChannel.Result) {
        if (barcodeView == null) {
            return barCodeViewNotSet(result)
        }
        barcodeView!!.pause()
        val settings = barcodeView!!.cameraSettings

        if (settings.requestedCameraId == CameraInfo.CAMERA_FACING_FRONT) {
            settings.requestedCameraId = CameraInfo.CAMERA_FACING_BACK
        } else {
            settings.requestedCameraId = CameraInfo.CAMERA_FACING_FRONT
        }

        barcodeView!!.cameraSettings = settings
        barcodeView!!.resume()
        result.success(settings.requestedCameraId)
    }

    private fun barCodeViewNotSet(result: MethodChannel.Result) {
        result.error("404", "No barcode view found", null)
    }

    private fun toggleFlash(result: MethodChannel.Result) {
        if (barcodeView == null) {
            return barCodeViewNotSet(result)
        }
        if (hasFlash()) {
            barcodeView!!.setTorch(!isTorchOn)
            isTorchOn = !isTorchOn
            result.success(isTorchOn)
        } else {
            result.error("404", "This device doesn't support flash", null)
        }

    }

    private fun pauseCamera(result: MethodChannel.Result) {
        if (barcodeView == null) {
            return barCodeViewNotSet(result)
        }
        if (barcodeView!!.isPreviewActive) {
            barcodeView!!.pause()
        }
        result.success(true)
    }

    private fun resumeCamera(result: MethodChannel.Result) {
        if (barcodeView == null) {
            return barCodeViewNotSet(result)
        }
        if (!barcodeView!!.isPreviewActive) {
            barcodeView!!.resume()
        }
        result.success(true)
    }

    private fun hasFlash(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
    }

    private fun hasBackCamera(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA)
    }

    private fun hasFrontCamera(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT)
    }

    private fun hasSystemFeature(feature: String): Boolean {
        return registrar.activeContext().packageManager
                .hasSystemFeature(feature)
    }

    override fun getView(): View {
        return initBarCodeView()?.apply {
            if (!hasBackCamera()) {
                if (!hasFrontCamera()) {
                    // TODO: Don t know what to do?
                } else {
                    this.cameraSettings.requestedCameraId = CameraInfo.CAMERA_FACING_FRONT
                }
            } else {
                this.cameraSettings.requestedCameraId = CameraInfo.CAMERA_FACING_BACK
            }
            resume()
        }!!
    }

    private fun initBarCodeView(): BarcodeView? {
        if (barcodeView == null) {
            barcodeView = createBarCodeView()
        }
        return barcodeView
    }

    private fun createBarCodeView(): BarcodeView? {
        val barcode = BarcodeView(registrar.activity())
        barcode.decodeContinuous(
                object : BarcodeCallback {
                    override fun barcodeResult(result: BarcodeResult) {
                        if (allowedBarcodeTypes.size == 0 || allowedBarcodeTypes.contains(result.barcodeFormat))
                            channel.invokeMethod("onRecognizeQR", result.text)
                    }

                    override fun possibleResultPoints(resultPoints: List<ResultPoint>) {}
                }
        )
        return barcode
    }

    override fun dispose() {
        barcodeView?.pause()
        barcodeView = null
    }

    private inner class CameraRequestPermissionsListener : PluginRegistry.RequestPermissionsResultListener {
        override fun onRequestPermissionsResult(id: Int, permissions: Array<String>, grantResults: IntArray): Boolean {
            if (id == CAMERA_REQUEST_ID && grantResults[0] == PERMISSION_GRANTED) {
                channel.invokeMethod("onPermissionSet", true)
                return true
            }

            channel.invokeMethod("onPermissionSet", false)
            return false
        }
    }

    private fun hasCameraPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                activity.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun showNativeAlertDialog(result: MethodChannel.Result) {
        AlertDialog.Builder(registrar.activeContext())
                .setTitle("Scanning Unavailable")
                .setMessage("This app does not have permission to access the camera")
                .setPositiveButton(R.string.ok, null)
                .setCancelable(false)
                .setIcon(R.drawable.ic_dialog_alert)
                .show()
        result.success(true)
    }

    private fun getSystemFeatures(result: MethodChannel.Result) {
        try {
            result.success(mapOf("hasFrontCamera" to hasFrontCamera(),
                    "hasBackCamera" to hasBackCamera(), "hasFlash" to hasFlash(),
                    "activeCamera" to barcodeView?.cameraSettings?.requestedCameraId))
        } catch (e: Exception) {
            result.error(null, null, null)
        }
    }

    private fun setBarcodeFormats(arguments: List<Int>, result: MethodChannel.Result) {
        try {
            allowedBarcodeTypes.clear()
            arguments.forEach {
                allowedBarcodeTypes.add(QRCodeTypes[it]!!)
            }
            result.success(true)
        } catch (e: java.lang.Exception) {
            result.error(null, null, null)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "flipCamera" -> {
                flipCamera(result)
            }
            "toggleFlash" -> {
                toggleFlash(result)
            }
            "pauseCamera" -> {
                pauseCamera(result)
            }
            "resumeCamera" -> {
                resumeCamera(result)
            }
            "showNativeAlertDialog" -> {
                showNativeAlertDialog(result)
            }
            "getSystemFeatures" -> {
                getSystemFeatures(result)
            }
            "setAllowedBarcodeFormats" -> {
                setBarcodeFormats(call.arguments as List<Int>, result)
            }
            else -> {
                result.error("404", "Method not implemented", null)
            }
        }
    }

    private fun checkAndRequestPermission() {
        if (hasCameraPermission()) {
            channel.invokeMethod("onPermissionSet", true)
        } else {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                registrar
                        .activity()
                        .requestPermissions(
                                arrayOf(Manifest.permission.CAMERA),
                                CAMERA_REQUEST_ID)
            } else {
                Log.e(QRView.javaClass.toString(), "Platform Version to low for camera permission check")
            }
        }
    }

}
