@file:Suppress("DEPRECATION")

package net.touchcapture.qr.mlkit

import android.annotation.TargetApi
import android.content.Context
import android.graphics.ImageFormat
import android.graphics.SurfaceTexture
import android.hardware.Camera
import android.util.Log
import android.util.SparseIntArray
import android.view.Surface
import android.view.WindowManager
import com.google.mlkit.vision.common.InputImage
import java.io.IOException

/**
 * Implements Camera using Deprecated Camera API
 */
@TargetApi(16)
internal class Camera1(private val targetWidth: Int, private val targetHeight: Int, private val texture: SurfaceTexture, private val context: Context, private val detector: MLKitDetector) :
    net.touchcapture.qr.mlkit.Camera {
    private var info = Camera.CameraInfo()
    private var camera: Camera? = null

    companion object {
        private const val TAG = "qr.mlkit.Camera1"
        private const val IMAGEFORMAT = ImageFormat.NV21
        private val ORIENTATIONS = SparseIntArray()

        init {
            ORIENTATIONS.append(Surface.ROTATION_0, 90)
            ORIENTATIONS.append(Surface.ROTATION_90, 0)
            ORIENTATIONS.append(Surface.ROTATION_180, 270)
            ORIENTATIONS.append(Surface.ROTATION_270, 180)
        }
    }

    // Return the corresponding MLKitImageMetadata rotation value.
    private val mlkitOrientation: Int
        get() {
            val windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            val deviceRotation = windowManager.defaultDisplay.rotation
            val rotationCompensation = (ORIENTATIONS[deviceRotation] + info.orientation + 270) % 360

            // Return the corresponding mlkitVisionImageMetadata rotation value.
            val result: Int
            when (rotationCompensation) {
                0 -> result = 0
                90 -> result = 90
                180 -> result = 180
                270 -> result = 270
                else -> {
                    result = Surface.ROTATION_0
                    Log.e(TAG, "Bad rotation value: $rotationCompensation")
                }
            }
            return result
        }

    @Throws(MLKitReader.Exception::class)
    override fun start() {
        val numberOfCameras = Camera.getNumberOfCameras()
        info = Camera.CameraInfo()
        for (i in 0 until numberOfCameras) {
            Camera.getCameraInfo(i, info)
            if (info.facing == Camera.CameraInfo.CAMERA_FACING_BACK) {
                camera = Camera.open(i)
                break
            }
        }
        if (camera == null) {
            throw Exception(MLKitReader.Exception.Reason.NoBackCamera.toString())
        }
        val parameters = camera!!.parameters
        val focusModes = parameters.supportedFocusModes
        if (focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
            Log.i(TAG, "Initializing with autofocus on.")
            parameters.focusMode = Camera.Parameters.FOCUS_MODE_AUTO
        } else {
            Log.i(TAG, "Initializing with autofocus off as not supported.")
        }
        val supportedSizes = parameters.supportedPreviewSizes
        val size = getAppropriateSize(supportedSizes)
        parameters.setPreviewSize(size.width, size.height)
        texture.setDefaultBufferSize(size.width, size.height)
        parameters.previewFormat = IMAGEFORMAT



        try {
            camera!!.setPreviewCallback { data, camera ->
                val previewSize = camera.parameters.previewSize
                if (data != null) {
                    val frame: MLKitDetector.Frame = Frame(data,
                            previewSize.width, previewSize.height, mlkitOrientation, IMAGEFORMAT
                    )
                    detector.detect(frame)
                }
            }
            camera!!.setPreviewTexture(texture)
            camera!!.startPreview()
            camera!!.autoFocus { success, camera -> }
        } catch (e: IOException) {
            e.printStackTrace()
        }
    }

    internal class Frame(private var data: ByteArray, private val width: Int, private val height: Int, private val rotationDegrees: Int, private val imageFormat: Int) :
        MLKitDetector.Frame {
        override fun toImage(): InputImage {
            return InputImage.fromByteArray(data, width, height, rotationDegrees, imageFormat)
        }

        override fun close() {
        }
    }

    override val width: Int
        get() = camera!!.parameters.previewSize.height
    override val height: Int
        get() = camera!!.parameters.previewSize.width
    override val orientation: Int
        get() = (info.orientation + 270) % 360

    override fun stop() {
        if (camera != null) {
            camera!!.stopPreview()
            camera!!.setPreviewCallback(null)
            camera!!.release()
            camera = null
        }
    }

    //Size here is Camera.Size, not android.util.Size as in the Camera2 version of this method
    private fun getAppropriateSize(sizes: List<Camera.Size>): Camera.Size {
        // assume sizes is never 0
        if (sizes.size == 1) return sizes[0]
        var s = sizes[0]
        val s1 = sizes[1]
        if (s1.width > s.width || s1.height > s.height) {
            // ascending
            if (info.orientation % 180 == 0) {
                for (size in sizes) {
                    s = size
                    if (size.height > targetHeight && size.width > targetWidth) {
                        break
                    }
                }
            } else {
                for (size in sizes) {
                    s = size
                    if (size.height > targetWidth && size.width > targetHeight) {
                        break
                    }
                }
            }
        } else {
            // descending
            if (info.orientation % 180 == 0) {
                for (size in sizes) {
                    if (size.height < targetHeight || size.width < targetWidth) {
                        break
                    }
                    s = size
                }
            } else {
                for (size in sizes) {
                    if (size.height < targetWidth || size.width < targetHeight) {
                        break
                    }
                    s = size
                }
            }
        }
        return s
    }

}