package net.touchcapture.qr.flutterqr

import android.Manifest
import android.app.Activity
import android.app.Application
import android.content.pm.PackageManager
import android.hardware.Camera.CameraInfo
import android.os.Build
import android.os.Bundle
import android.view.View
import com.google.zxing.BarcodeFormat
import com.google.zxing.ResultPoint
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.BarcodeView
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView

class QRView(messenger: BinaryMessenger, id: Int, private val params: HashMap<String, Any>) :
        PlatformView, MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {

    private var isTorchOn: Boolean = false
    private var isPaused: Boolean = false
    private var barcodeView: BarcodeView? = null
    private val channel: MethodChannel = MethodChannel(messenger, "net.touchcapture.qr.flutterqr/qrview_$id")
    private var permissionGranted: Boolean = false

    init {
        if (Shared.binding != null) {
            Shared.binding!!.addRequestPermissionsResultListener(this)
        }

        if (Shared.registrar != null) {
            Shared.registrar!!.addRequestPermissionsResultListener(this)
        }

        channel.setMethodCallHandler(this)
        Shared.activity?.application?.registerActivityLifecycleCallbacks(object : Application.ActivityLifecycleCallbacks {
            override fun onActivityPaused(p0: Activity) {
                if (p0 == Shared.activity && !isPaused && hasCameraPermission()) {
                    barcodeView?.pause()
                }
            }

            override fun onActivityResumed(p0: Activity) {
                if (p0 == Shared.activity && !isPaused && hasCameraPermission()) {
                    barcodeView?.resume()
                }
            }

            override fun onActivityStarted(p0: Activity) {
            }

            override fun onActivityDestroyed(p0: Activity) {
            }

            override fun onActivitySaveInstanceState(p0: Activity, p1: Bundle) {
            }

            override fun onActivityStopped(p0: Activity) {
            }

            override fun onActivityCreated(p0: Activity, p1: Bundle?) {
            }
        })
    }

    override fun dispose() {
        barcodeView?.pause()
        barcodeView = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        when(call.method) {
            "startScan" -> startScan(call.arguments as? List<Int>, result)
            "stopScan" -> stopScan()
            "flipCamera" -> flipCamera(result)
            "toggleFlash" -> toggleFlash(result)
            "pauseCamera" -> pauseCamera(result)
            // Stopping camera is the same as pausing camera
            "stopCamera" -> pauseCamera(result)
            "resumeCamera" -> resumeCamera(result)
            "requestPermissions" -> checkAndRequestPermission(result)
            "getCameraInfo" -> getCameraInfo(result)
            "getFlashInfo" -> getFlashInfo(result)
            "getSystemFeatures" -> getSystemFeatures(result)
            else -> result.notImplemented()
        }
    }

    private fun getCameraInfo(result: MethodChannel.Result) {
        if (barcodeView == null) {
            return barCodeViewNotSet(result)
        }
        result.success(barcodeView!!.cameraSettings.requestedCameraId)
    }

    private fun flipCamera(result: MethodChannel.Result) {
        if (barcodeView == null) {
            return barCodeViewNotSet(result)
        } else if (!hasCameraPermission()) {
            checkAndRequestPermission(result)
        } else {
            barcodeView!!.pause()
            val settings = barcodeView!!.cameraSettings

            if(settings.requestedCameraId == CameraInfo.CAMERA_FACING_FRONT)
                settings.requestedCameraId = CameraInfo.CAMERA_FACING_BACK
            else
                settings.requestedCameraId = CameraInfo.CAMERA_FACING_FRONT

            barcodeView!!.cameraSettings = settings
            barcodeView!!.resume()
            result.success(settings.requestedCameraId)
        }


    }

    private fun getFlashInfo(result: MethodChannel.Result) {
        if (barcodeView == null) {
            return barCodeViewNotSet(result)
        }
        result.success(isTorchOn)
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
        } else if (!hasCameraPermission()) {
            checkAndRequestPermission(result)
        } else {
            if (barcodeView!!.isPreviewActive) {
                isPaused = true
                barcodeView!!.pause()
            }
            result.success(true)
        }
    }

    private fun resumeCamera(result: MethodChannel.Result) {
        if (barcodeView == null) {
            return barCodeViewNotSet(result)
        } else if (!hasCameraPermission()) {
            checkAndRequestPermission(result)
        } else {
            if (!barcodeView!!.isPreviewActive) {
                isPaused = false
                barcodeView!!.resume()
            }
            result.success(true)
        }
    }

    private fun hasFlash(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
    }

    private fun hasBackCamera(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA_ANY)
    }

    private fun hasFrontCamera(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT)
    }

    private fun hasSystemFeature(feature: String): Boolean {
        return Shared.activity!!.packageManager
                .hasSystemFeature(feature)
    }

    private fun barCodeViewNotSet(result: MethodChannel.Result) {
        result.error("404", "No barcode view found", null)
    }

    override fun getView(): View {
        return initBarCodeView().apply {}!!
    }

    private fun initBarCodeView(): BarcodeView? {
        if (barcodeView == null) {
            barcodeView = BarcodeView(Shared.activity)
            if (params["cameraFacing"] as Int == 1) {
                barcodeView?.cameraSettings?.requestedCameraId = CameraInfo.CAMERA_FACING_FRONT
            }
        } else {
            if (hasCameraPermission()) {
                if (!isPaused) barcodeView!!.resume()
            } else {
                checkAndRequestPermission(null)
            }
        }
        return barcodeView
    }

    private fun startScan(arguments: List<Int>?, result: MethodChannel.Result) {
        val allowedBarcodeTypes = mutableListOf<BarcodeFormat>()
        try {
            checkAndRequestPermission(result)

            arguments?.forEach {
                allowedBarcodeTypes.add(BarcodeFormat.values()[it])
            }
        } catch (e: java.lang.Exception) {
            result.error(null, null, null)
        }

        barcodeView?.decodeContinuous(
                object : BarcodeCallback {
                    override fun barcodeResult(result: BarcodeResult) {
                        if (allowedBarcodeTypes.size == 0 || allowedBarcodeTypes.contains(result.barcodeFormat)) {
                            val code = mapOf(
                                    "code" to result.text,
                                    "type" to result.barcodeFormat.name,
                                    "rawBytes" to result.rawBytes)
                            channel.invokeMethod("onRecognizeQR", code)
                        }

                    }

                    override fun possibleResultPoints(resultPoints: List<ResultPoint>) {}
                }
        )
    }

    private fun stopScan() {
        barcodeView?.stopDecoding()
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

    private fun hasCameraPermission(): Boolean {
        return permissionGranted ||
                Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                Shared.activity?.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED
    }

    private fun checkAndRequestPermission(result: MethodChannel.Result?) {
        when {
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
                if (Shared.activity?.checkSelfPermission(Manifest.permission.CAMERA) == PackageManager.PERMISSION_GRANTED) {
                    permissionGranted = true
                    channel.invokeMethod("onPermissionSet", true)
                } else {
                    Shared.activity?.requestPermissions(
                            arrayOf(Manifest.permission.CAMERA),
                            Shared.CAMERA_REQUEST_ID)
                }
            }
            else -> {
                result?.error("cameraPermission", "Platform Version to low for camera permission check", null)
            }
        }
    }

    override fun onRequestPermissionsResult( requestCode: Int,
                                             permissions: Array<out String>?,
                                             grantResults: IntArray): Boolean {

        if (requestCode == Shared.CAMERA_REQUEST_ID && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            permissionGranted = true
            channel.invokeMethod("onPermissionSet", true)
            return true
        }
        permissionGranted = false
        channel.invokeMethod("onPermissionSet", false)
        return false
    }

}

