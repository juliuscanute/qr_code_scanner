package net.touchcapture.qr.mlkit

import android.Manifest
import android.util.Log
import androidx.core.app.ActivityCompat
import com.google.mlkit.vision.barcode.Barcode
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry.SurfaceTextureEntry
import net.touchcapture.qr.flutterqr.Shared
import net.touchcapture.qr.flutterqr.Shared.activity
import net.touchcapture.qr.flutterqr.Shared.textures
import java.io.IOException
import java.util.*

class MLKitScanner : MethodChannel.MethodCallHandler, MLKitCallbacks,
    MLKitReader.MLKitStartedCallback {

    private var waitingForPermissionResult = false
    private var permissionDenied = false
    private var readingInstance: ReadingInstance? = null

    private fun stopReader() {
        if (readingInstance != null) {
            readingInstance!!.reader.stop()
            readingInstance!!.textureEntry.release()
        }
        readingInstance = null
    }

    override fun onMethodCall(methodCall: MethodCall, result: MethodChannel.Result) {
        when (methodCall.method) {
            "startMLKit" -> {
                when {
                    permissionDenied -> {
                        permissionDenied = false
                        result.error("MLKitReader_ERROR", "noPermission", null)
                    }
                    readingInstance != null -> {
                        result.error(
                            "ALREADY_RUNNING",
                            "Start cannot be called when already running",
                            ""
                        )
                    }
                    else -> {
                        val targetWidth = methodCall.argument<Int>("targetWidth")!!
                        val targetHeight = methodCall.argument<Int>("targetHeight")!!
                        val formatStrings = methodCall.argument<List<String>>("formats")!!
                        val options = BarcodeFormats.optionsFromStringList(formatStrings)
                        val textureEntry = textures!!.createSurfaceTexture()
                        val reader = MLKitReader(
                            targetWidth, targetHeight, activity!!, options,
                            this, this, textureEntry.surfaceTexture()
                        )
                        readingInstance = ReadingInstance(reader, textureEntry, result)
                        try {
                            reader.start()
                        } catch (e: IOException) {
                            e.printStackTrace()
                            result.error(
                                "IOException",
                                "Error starting camera because of IOException: " + e.localizedMessage,
                                null
                            )
                        } catch (e: MLKitReader.Exception) {
                            if (e.reason() == MLKitReader.Exception.Reason.NoPermissions) {
                                waitingForPermissionResult = true
                                ActivityCompat.requestPermissions(
                                    activity!!,
                                    arrayOf(Manifest.permission.CAMERA),
                                    REQUEST_PERMISSION
                                )
                            } else {
                                e.printStackTrace()
                                result.error(
                                    e.reason().name,
                                    "Error starting camera for reason: " + e.reason().name,
                                    null
                                )
                            }
                        }
                    }
                }
            }
            "stopMLKit" -> {
                if (readingInstance != null && !waitingForPermissionResult) {
                    stopReader()
                }
                result.success(null)
            }
//            "flipCamera" -> flipCamera(result)
            else -> result.notImplemented()
        }
    }

    override fun qrRead(barcode: Barcode) {
        val valueType = barcode.valueType
        val format = barcode.format
        val displayValue = barcode.displayValue
        val rawValue = barcode.rawValue

        val boundingBox = barcode.boundingBox!!.flattenToString()

        // TODO: Other barcode values

        val code = mapOf(
            "valueType" to valueType,
            "format" to format,
            "displayValue" to displayValue,
            "rawValue" to rawValue,
            "boundingBox" to boundingBox
        )
        Shared.mlkitChannel!!.invokeMethod("qrRead", code)
    }

    override fun started() {
        val response: MutableMap<String, Any?> = HashMap()
        response["surfaceWidth"] = readingInstance?.reader?.mlkitCamera?.width
        response["surfaceHeight"] = readingInstance?.reader?.mlkitCamera?.height
        response["surfaceOrientation"] = readingInstance?.reader?.mlkitCamera?.orientation
        response["textureId"] = readingInstance?.textureEntry?.id()
        readingInstance?.startResult?.success(response)
    }

    private fun stackTraceAsString(stackTrace: Array<StackTraceElement>?): List<String>? {
        if (stackTrace == null) {
            return null
        }
        val stackTraceStrings: MutableList<String> = ArrayList(stackTrace.size)
        for (el in stackTrace) {
            stackTraceStrings.add(el.toString())
        }
        return stackTraceStrings
    }

    override fun startingFailed(t: Throwable?) {
        Log.w(TAG, "Starting MLKit failed", t)
        val stackTraceStrings = stackTraceAsString(t!!.stackTrace)
        if (t is MLKitReader.Exception) {
            val qrException: MLKitReader.Exception = t
            readingInstance?.startResult?.error(
                "MLKitReader_ERROR",
                qrException.reason().name,
                stackTraceStrings
            )
        } else {
            readingInstance?.startResult?.error("UNKNOWN_ERROR", t.message, stackTraceStrings)
        }
    }

    private inner class ReadingInstance(
        val reader: MLKitReader,
        val textureEntry: SurfaceTextureEntry,
        val startResult: MethodChannel.Result
    )

    companion object {
        private const val TAG = "qr.mlkit.reader"
        private const val REQUEST_PERMISSION = 1
    }
}