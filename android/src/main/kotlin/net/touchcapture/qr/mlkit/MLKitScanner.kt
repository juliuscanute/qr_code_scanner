package net.touchcapture.qr.mlkit

import android.Manifest
import android.util.Log
import androidx.core.app.ActivityCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.TextureRegistry.SurfaceTextureEntry
import net.touchcapture.qr.flutterqr.Shared
import net.touchcapture.qr.flutterqr.Shared.activity
import net.touchcapture.qr.flutterqr.Shared.textures
import java.io.IOException
import java.util.*

class MLKitScanner : MethodChannel.MethodCallHandler, MLKitCallbacks, MLKitReader.MLKitStartedCallback {

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
              result.error("ALREADY_RUNNING", "Start cannot be called when already running", "")
            }
            else -> {
              val targetWidth = methodCall.argument<Int>("targetWidth")!!
              val targetHeight = methodCall.argument<Int>("targetHeight")!!
              val formatStrings = methodCall.argument<List<String>>("formats")!!
              val options = BarcodeFormats.optionsFromStringList(formatStrings)
              val textureEntry = textures!!.createSurfaceTexture()
              val reader = MLKitReader(targetWidth, targetHeight, activity!!, options,
                      this, this, textureEntry.surfaceTexture())
              readingInstance = ReadingInstance(reader, textureEntry, result)
              try {
                reader.start()
              } catch (e: IOException) {
                e.printStackTrace()
                result.error("IOException", "Error starting camera because of IOException: " + e.localizedMessage, null)
              } catch (e: MLKitReader.Exception) {
                e.printStackTrace()
                result.error(e.reason().name, "Error starting camera for reason: " + e.reason().name, null)
              } catch (e: NoPermissionException) {
                waitingForPermissionResult = true
                ActivityCompat.requestPermissions(activity!!, arrayOf(Manifest.permission.CAMERA), REQUEST_PERMISSION)
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
      else -> result.notImplemented()
    }
  }

  override fun qrRead(data: String?) {
    Shared.mlkitChannel!!.invokeMethod("qrRead", data)
  }

  override fun started() {
    val response: MutableMap<String, Any?> = HashMap()
    response["surfaceWidth"] = readingInstance?.reader?.qrCamera?.width
    response["surfaceHeight"] = readingInstance?.reader?.qrCamera?.height
    response["surfaceOrientation"] = readingInstance?.reader?.qrCamera?.orientation
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
      readingInstance?.startResult?.error("MLKitReader_ERROR", qrException.reason().name, stackTraceStrings)
    } else {
      readingInstance?.startResult?.error("UNKNOWN_ERROR", t.message, stackTraceStrings)
    }
  }

  private inner class ReadingInstance(val reader: MLKitReader, val textureEntry: SurfaceTextureEntry, val startResult: MethodChannel.Result)

  companion object {
    private const val TAG = "qr.mlkit.reader"
    private const val REQUEST_PERMISSION = 1

  }
}