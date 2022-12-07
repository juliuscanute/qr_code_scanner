package net.touchcapture.qr.flutterqr

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.view.View
import androidx.core.content.ContextCompat
import com.google.zxing.BarcodeFormat
import com.google.zxing.ResultPoint
import android.graphics.BitmapFactory
import com.google.zxing.BinaryBitmap
import com.google.zxing.DecodeHintType
import com.google.zxing.RGBLuminanceSource
import com.google.zxing.common.HybridBinarizer
import com.google.zxing.qrcode.QRCodeReader
import com.journeyapps.barcodescanner.BarcodeCallback
import com.journeyapps.barcodescanner.BarcodeResult
import com.journeyapps.barcodescanner.DefaultDecoderFactory
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformView
import java.util.*

class QRView(
    private val context: Context,
    messenger: BinaryMessenger,
    private val id: Int,
    private val params: HashMap<String, Any>
) : PlatformView, MethodChannel.MethodCallHandler, PluginRegistry.RequestPermissionsResultListener {

    private val cameraRequestCode = QrShared.CAMERA_REQUEST_ID + this.id

    private val channel: MethodChannel = MethodChannel(
        messenger, "net.touchcapture.qr.flutterqr/qrview_$id"
    )
    private val cameraFacingBack = 0
    private val cameraFacingFront = 1

    private var isRequestingPermission = false
    private var isTorchOn = false
    private var isPaused = false
    private var barcodeView: CustomFramingRectBarcodeView? = null
    private var unRegisterLifecycleCallback: UnRegisterLifecycleCallback? = null

    init {
        QrShared.binding?.addRequestPermissionsResultListener(this)

        channel.setMethodCallHandler(this)

        unRegisterLifecycleCallback = QrShared.activity?.registerLifecycleCallbacks(
            onPause = {
                if (!isPaused && hasCameraPermission) barcodeView?.pause()

            },
            onResume = {
                if (!hasCameraPermission && !isRequestingPermission) checkAndRequestPermission()
                else if (!isPaused && hasCameraPermission) barcodeView?.resume()
            }
        )
    }

    override fun dispose() {
        unRegisterLifecycleCallback?.invoke()

        QrShared.binding?.removeRequestPermissionsResultListener(this)

        barcodeView?.pause()
        barcodeView = null
    }

    override fun getView(): View = initBarCodeView()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        @Suppress("UNCHECKED_CAST")
        when (call.method) {
            "startScan" -> startScan(call.arguments as? List<Int>, result)

            "stopScan" -> stopScan()

            "flipCamera" -> flipCamera(result)

            "toggleFlash" -> toggleFlash(result)

            "pauseCamera" -> pauseCamera(result)

            // Stopping camera is the same as pausing camera
            "stopCamera" -> pauseCamera(result)

            "resumeCamera" -> resumeCamera(result)

            "requestPermissions" -> checkAndRequestPermission()

            "getCameraInfo" -> getCameraInfo(result)

            "getFlashInfo" -> getFlashInfo(result)

            "getSystemFeatures" -> getSystemFeatures(result)

            "changeScanArea" -> changeScanArea(
                dpScanAreaWidth = requireNotNull(call.argument<Double>("scanAreaWidth")),
                dpScanAreaHeight = requireNotNull(call.argument<Double>("scanAreaHeight")),
                cutOutBottomOffset = requireNotNull(call.argument<Double>("cutOutBottomOffset")),
                result = result,
            )

            "invertScan" -> setInvertScan(
                isInvert = call.argument<Boolean>("isInvertScan") ?: false,
            )

            "scanQrcodeFromGallery" -> scanQrcodeFromGallery(call.arguments as? String, result)

            else -> result.notImplemented()
        }
    }

    private fun scanQrcodeFromGallery(path: String?, result: MethodChannel.Result) {
        // val path = call.arguments as String
        // DecodeHintType 和EncodeHintType
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true
        BitmapFactory.decodeFile(path, options)
        options.inJustDecodeBounds = false
        options.inSampleSize = 1
        val bitmap = BitmapFactory.decodeFile(path, options)
        val width = bitmap.width
        val height = bitmap.height
        val pixels = IntArray(width * height)
        bitmap.getPixels(pixels, 0, width, 0, 0, width, height)
        val source = RGBLuminanceSource(width, height, pixels)
        val hints: Hashtable<DecodeHintType, String> = Hashtable<DecodeHintType, String>()
        hints[DecodeHintType.CHARACTER_SET] = "utf-8" // 设置二维码内容的编码
        try {
            val result1 = QRCodeReader().decode(BinaryBitmap(HybridBinarizer(source)), hints)
            result.success(listOf(result1.text))
        } catch (e: Exception) {
            // nothing qrcode found
            val list: List<String> = listOf()
            result.success(list)
        }
    }

    private fun initBarCodeView(): CustomFramingRectBarcodeView {
        var barcodeView = barcodeView

        if (barcodeView == null) {
            barcodeView = CustomFramingRectBarcodeView(QrShared.activity).also {
                this.barcodeView = it
            }

            barcodeView.decoderFactory = DefaultDecoderFactory(null, null, null, 2)

            if (params[PARAMS_CAMERA_FACING] as Int == 1) {
                barcodeView.cameraSettings?.requestedCameraId = cameraFacingFront
            }
        } else if (!isPaused) {
            barcodeView.resume()
        }

        return barcodeView
    }

    // region Camera Info

    private fun getCameraInfo(result: MethodChannel.Result) {
        val barcodeView = barcodeView ?: return barCodeViewNotSet(result)

        result.success(barcodeView.cameraSettings.requestedCameraId)
    }

    private fun getFlashInfo(result: MethodChannel.Result) {
        if (barcodeView == null) return barCodeViewNotSet(result)

        result.success(isTorchOn)
    }

    private fun hasFlash(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
    }

    @SuppressLint("UnsupportedChromeOsCameraSystemFeature")
    private fun hasBackCamera(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA)
    }

    private fun hasFrontCamera(): Boolean {
        return hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT)
    }

    private fun hasSystemFeature(feature: String): Boolean =
        context.packageManager.hasSystemFeature(feature)

    private fun getSystemFeatures(result: MethodChannel.Result) {
        try {
            result.success(
                mapOf(
                    "hasFrontCamera" to hasFrontCamera(),
                    "hasBackCamera" to hasBackCamera(),
                    "hasFlash" to hasFlash(),
                    "activeCamera" to barcodeView?.cameraSettings?.requestedCameraId
                )
            )
        } catch (e: Exception) {
            result.error("", e.message, null)
        }
    }

    // endregion

    // region Camera Controls

    private fun flipCamera(result: MethodChannel.Result) {
        val barcodeView = barcodeView ?: return barCodeViewNotSet(result)

        barcodeView.pause()

        val settings = barcodeView.cameraSettings
        if (settings.requestedCameraId == cameraFacingFront) {
            settings.requestedCameraId = cameraFacingBack
        } else settings.requestedCameraId = cameraFacingFront

        barcodeView.resume()

        result.success(settings.requestedCameraId)
    }

    private fun toggleFlash(result: MethodChannel.Result) {
        val barcodeView = barcodeView ?: return barCodeViewNotSet(result)

        if (hasFlash()) {
            barcodeView.setTorch(!isTorchOn)
            isTorchOn = !isTorchOn
            result.success(isTorchOn)
        } else {
            result.error(ERROR_CODE_NOT_SET, ERROR_MESSAGE_FLASH_NOT_FOUND, null)
        }
    }

    private fun pauseCamera(result: MethodChannel.Result) {
        val barcodeView = barcodeView ?: return barCodeViewNotSet(result)

        if (barcodeView.isPreviewActive) {
            isPaused = true
            barcodeView.pause()
        }

        result.success(true)
    }

    private fun resumeCamera(result: MethodChannel.Result) {
        val barcodeView = barcodeView ?: return barCodeViewNotSet(result)

        if (!barcodeView.isPreviewActive) {
            isPaused = false
            barcodeView.resume()
        }

        result.success(true)
    }

    private fun startScan(arguments: List<Int>?, result: MethodChannel.Result) {
        checkAndRequestPermission()

        val allowedBarcodeTypes = getAllowedBarcodeTypes(arguments, result)

        barcodeView?.decodeContinuous(
            object : BarcodeCallback {
                override fun barcodeResult(result: BarcodeResult) {
                    if (allowedBarcodeTypes.isEmpty() || allowedBarcodeTypes.contains(result.barcodeFormat)) {
                        val code = mapOf(
                            "code" to result.text,
                            "type" to result.barcodeFormat.name,
                            "rawBytes" to result.rawBytes
                        )

                        channel.invokeMethod(CHANNEL_METHOD_ON_RECOGNIZE_QR, code)
                    }
                }

                override fun possibleResultPoints(resultPoints: List<ResultPoint>) = Unit
            }
        )
    }

    private fun stopScan() {
        barcodeView?.stopDecoding()
    }

    private fun setInvertScan(isInvert: Boolean) {
        val barcodeView = barcodeView ?: return
        with(barcodeView) {
            pause()
            cameraSettings.isScanInverted = isInvert
            resume()
        }
    }

    private fun changeScanArea(
        dpScanAreaWidth: Double,
        dpScanAreaHeight: Double,
        cutOutBottomOffset: Double,
        result: MethodChannel.Result
    ) {
        setScanAreaSize(dpScanAreaWidth, dpScanAreaHeight, cutOutBottomOffset)

        result.success(true)
    }

    private fun setScanAreaSize(
        dpScanAreaWidth: Double,
        dpScanAreaHeight: Double,
        dpCutOutBottomOffset: Double
    ) {
        barcodeView?.setFramingRect(
            dpScanAreaWidth.convertDpToPixels(),
            dpScanAreaHeight.convertDpToPixels(),
            dpCutOutBottomOffset.convertDpToPixels(),
        )
    }

    // endregion

    // region permissions

    private val hasCameraPermission: Boolean
        get() = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.CAMERA
                ) == PackageManager.PERMISSION_GRANTED

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != cameraRequestCode) return false
        isRequestingPermission = false

        val permissionGranted =
            grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED

        channel.invokeMethod(CHANNEL_METHOD_ON_PERMISSION_SET, permissionGranted)

        return permissionGranted
    }



    private fun checkAndRequestPermission() {
        if (hasCameraPermission) {
            channel.invokeMethod(CHANNEL_METHOD_ON_PERMISSION_SET, true)
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !isRequestingPermission) {
            QrShared.activity?.requestPermissions(
                arrayOf(Manifest.permission.CAMERA),
                cameraRequestCode
            )
        }
    }

    // endregion

    // region barcode common

    private fun getAllowedBarcodeTypes(
        arguments: List<Int>?,
        result: MethodChannel.Result
    ): List<BarcodeFormat> {
        return try {
            arguments?.map {
                BarcodeFormat.values()[it]
            }.orEmpty()
        } catch (e: Exception) {
            result.error("", e.message, null)

            emptyList()
        }
    }

    private fun barCodeViewNotSet(result: MethodChannel.Result) {
        result.error(
            ERROR_CODE_NOT_SET,
            ERROR_MESSAGE_NOT_SET,
            null
        )
    }

    // endregion

    // region helpers

    private fun Double.convertDpToPixels() =
        (this * context.resources.displayMetrics.density).toInt()

    // endregion

    companion object {
        private const val CHANNEL_METHOD_ON_PERMISSION_SET = "onPermissionSet"
        private const val CHANNEL_METHOD_ON_RECOGNIZE_QR = "onRecognizeQR"

        private const val PARAMS_CAMERA_FACING = "cameraFacing"

        private const val ERROR_CODE_NOT_SET = "404"

        private const val ERROR_MESSAGE_NOT_SET = "No barcode view found"
        private const val ERROR_MESSAGE_FLASH_NOT_FOUND = "This device doesn't support flash"
    }
}

