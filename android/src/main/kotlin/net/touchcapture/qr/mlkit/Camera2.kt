package net.touchcapture.qr.mlkit

import android.annotation.TargetApi
import android.content.Context
import android.graphics.ImageFormat
import android.graphics.SurfaceTexture
import android.hardware.camera2.*
import android.media.Image
import android.media.ImageReader
import android.util.Log
import android.util.Size
import android.util.SparseIntArray
import android.view.Surface
import androidx.annotation.RequiresApi
import com.google.mlkit.vision.common.InputImage
import io.flutter.plugin.common.MethodChannel
import java.util.*
import android.hardware.camera2.CameraAccessException

import android.hardware.camera2.CameraCharacteristics

import android.os.Build




/**
 * Implements QrCamera using Camera2 API
 */
@TargetApi(21)
@RequiresApi(21)
internal class Camera2(private val targetWidth: Int, private val targetHeight: Int, private val texture: SurfaceTexture, private val context: Context,
                       private val detector: MLKitDetector
) : Camera {
    companion object {
        private const val TAG = "qr.mlkit.Camera2"
        private val ORIENTATIONS = SparseIntArray()

        init {
            ORIENTATIONS.append(Surface.ROTATION_0, 90)
            ORIENTATIONS.append(Surface.ROTATION_90, 0)
            ORIENTATIONS.append(Surface.ROTATION_180, 270)
            ORIENTATIONS.append(Surface.ROTATION_270, 180)
        }
    }

    private var size: Size? = null
    private var reader: ImageReader? = null
    private var previewBuilder: CaptureRequest.Builder? = null
    private var previewSession: CameraCaptureSession? = null
    private var jpegSizes: Array<Size>? = null
    private var sensorOrientation = 0
    private var cameraDevice: CameraDevice? = null
    private var cameraCharacteristics: CameraCharacteristics? = null
    private var latestFrame: Frame? = null
    private var manager: CameraManager? = null
    private var cameraId: String? = null
    override val width: Int
        get() = size!!.width
    override val height: Int
        get() = size!!.height

    // ignore sensor orientation of devices with 'reverse landscape' orientation of sensor
    // as camera2 api seems to already rotate the output.
    override val orientation: Int
        get() = if (sensorOrientation == 270) 90 else sensorOrientation

    // Return the corresponding MLKitVisionImageMetadata rotation value.
    private val mlkitOrientation: Int
        get() {
            val deviceRotation = context.display?.rotation ?: return 0
            val rotationCompensation = (ORIENTATIONS[deviceRotation] + sensorOrientation + 270) % 360

            val result: Int
            when (rotationCompensation) {
                0 -> result = 0
                90 -> result = 90
                180 -> result = 180
                270 -> result = 270
                else -> {
                    result = 0
                    Log.e(TAG, "Bad rotation value: $rotationCompensation")
                }
            }
            return result
        }

    @Throws(MLKitReader.Exception::class)
    override fun start(params: HashMap<String, Any>) {
        manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        try {
            val cameraIdList = manager!!.cameraIdList
            for (id in cameraIdList) {
                val cameraCharacteristics = manager!!.getCameraCharacteristics(id!!)
                val integer = cameraCharacteristics.get(CameraCharacteristics.LENS_FACING)
                // First check if a front camera is available
                if (integer != null && params["cameraFacing"] as Int == 1 && integer == CameraMetadata.LENS_FACING_FRONT) {
                    cameraId = id
                } else if (integer != null && params["cameraFacing"] as Int != 1 && integer == CameraMetadata.LENS_FACING_BACK) {
                    cameraId = id
                    break
                }
            }
            // If no front camera is available, fall back to rear camera
            if (params["cameraFacing"] as Int == 1 && cameraId == null) {
                for (id in cameraIdList) {
                    val cameraCharacteristics = manager!!.getCameraCharacteristics(id!!)
                    val integer = cameraCharacteristics.get(CameraCharacteristics.LENS_FACING)
                        if (integer != null && integer == CameraMetadata.LENS_FACING_BACK) {
                        cameraId = id
                        break
                    }
                }
            }
        } catch (e: CameraAccessException) {
            Log.w(TAG, "Error getting back camera.", e)
            throw RuntimeException(e)
        }
        if (cameraId == null) {
            throw Exception(MLKitReader.Exception.Reason.NoBackCamera.toString())
        }
        try {
            cameraCharacteristics = manager!!.getCameraCharacteristics(cameraId!!)
            val map = cameraCharacteristics!!.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            val sensorOrientationInteger = cameraCharacteristics!!.get(CameraCharacteristics.SENSOR_ORIENTATION)
            sensorOrientation = sensorOrientationInteger ?: 0
            size = getAppropriateSize(map!!.getOutputSizes(SurfaceTexture::class.java))
            jpegSizes = map.getOutputSizes(ImageFormat.JPEG)
            manager!!.openCamera(cameraId!!, object : CameraDevice.StateCallback() {
                override fun onOpened(device: CameraDevice) {
                    cameraDevice = device
                    startCamera()
                }

                override fun onDisconnected(device: CameraDevice) {}
                override fun onError(device: CameraDevice, error: Int) {
                    Log.w(TAG, "Error opening camera: $error")
                }
            }, null)
        } catch (e: CameraAccessException) {
            Log.w(TAG, "Error getting camera configuration.", e)
        }
    }

    private fun afMode(cameraCharacteristics: CameraCharacteristics?): Int? {
        val afModes = cameraCharacteristics!!.get(CameraCharacteristics.CONTROL_AF_AVAILABLE_MODES)
                ?: return null
        val modes = HashSet<Int>(afModes.size * 2)
        for (afMode in afModes) {
            modes.add(afMode)
        }
        return when {
            modes.contains(CameraMetadata.CONTROL_AF_MODE_CONTINUOUS_VIDEO) -> {
                CameraMetadata.CONTROL_AF_MODE_CONTINUOUS_VIDEO
            }
            modes.contains(CameraMetadata.CONTROL_AF_MODE_CONTINUOUS_PICTURE) -> {
                CameraMetadata.CONTROL_AF_MODE_CONTINUOUS_PICTURE
            }
            modes.contains(CameraMetadata.CONTROL_AF_MODE_AUTO) -> {
                CameraMetadata.CONTROL_AF_MODE_AUTO
            }
            else -> {
                null
            }
        }
    }

    internal class Frame(private val image: Image, private val mlkitOrientation: Int) : MLKitDetector.Frame {
        override fun toImage(): InputImage {
            return InputImage.fromMediaImage(image, mlkitOrientation)
        }

        override fun close() {
            image.close()
        }
    }

    private fun startCamera() {
        val list: MutableList<Surface> = ArrayList()
        val jpegSize = getAppropriateSize(jpegSizes)
        val width = jpegSize.width
        val height = jpegSize.height
        reader = ImageReader.newInstance(width, height, ImageFormat.YUV_420_888, 5)
        list.add(reader!!.surface)
        val imageAvailableListener = ImageReader.OnImageAvailableListener { reader ->
            try {
                val image = reader.acquireLatestImage() ?: return@OnImageAvailableListener
                latestFrame = Frame(image, mlkitOrientation)
                detector.detect(latestFrame)
            } catch (t: Throwable) {
                t.printStackTrace()
            }
        }
        reader!!.setOnImageAvailableListener(imageAvailableListener, null)
        texture.setDefaultBufferSize(size!!.width, size!!.height)
        list.add(Surface(texture))
        try {
            previewBuilder = cameraDevice!!.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
            previewBuilder!!.addTarget(list[0])
            previewBuilder!!.addTarget(list[1])
            val afMode = afMode(cameraCharacteristics)
            previewBuilder!!.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO)
            if (afMode != null) {
                previewBuilder!!.set(CaptureRequest.CONTROL_AF_MODE, afMode)
                Log.i(TAG, "Setting af mode to: $afMode")
                if (afMode == CameraMetadata.CONTROL_AF_MODE_AUTO) {
                    previewBuilder!!.set(CaptureRequest.CONTROL_AF_TRIGGER, CaptureRequest.CONTROL_AF_TRIGGER_START)
                } else {
                    previewBuilder!!.set(CaptureRequest.CONTROL_AF_TRIGGER, CaptureRequest.CONTROL_AF_TRIGGER_CANCEL)
                }
            }
        } catch (e: java.lang.Exception) {
            e.printStackTrace()
            return
        }
        try {
            @Suppress("DEPRECATION") // see https://stackoverflow.com/a/67084110/13031778
            cameraDevice!!.createCaptureSession(list, object : CameraCaptureSession.StateCallback() {
                override fun onConfigured(session: CameraCaptureSession) {
                    previewSession = session
                    startPreview()
                }

                override fun onConfigureFailed(session: CameraCaptureSession) {
                    println("### Configuration Fail ###")
                }
            }, null)
        } catch (t: Throwable) {
            t.printStackTrace()
        }
    }

    private fun startPreview() {
        val listener: CameraCaptureSession.CaptureCallback = object : CameraCaptureSession.CaptureCallback() {}
        if (cameraDevice == null) return
        try {
            previewSession!!.setRepeatingRequest(previewBuilder!!.build(), listener, null)
        } catch (e: java.lang.Exception) {
            e.printStackTrace()
        }
    }

    override fun stop() {
        if (cameraDevice != null) cameraDevice!!.close()

        if (reader != null) {
            if (latestFrame != null) latestFrame!!.close()
            latestFrame = null
            reader!!.close()
        }
    }

    private var isTorchOn: Boolean = false

    private fun toggleFlash(result: MethodChannel.Result) {

//            val mCameraManager = context.getSystemService(Context.CAMERA_SERVICE)
//            try {
//                var mCameraId = ""
//                for (camID in mCameraManager.cameraIdList) {
//                    val cameraCharacteristics: CameraCharacteristics =
//                        mCameraManager.getCameraCharacteristics(camID)
//                    val lensFacing =
//                        cameraCharacteristics.get(CameraCharacteristics.LENS_FACING)!!
//                    if (lensFacing == CameraCharacteristics.LENS_FACING_FRONT && cameraCharacteristics.get(
//                            CameraCharacteristics.FLASH_INFO_AVAILABLE
//                        )!!
//                    ) {
//                        mCameraId = camID
//                        break
//                    } else if (lensFacing == CameraCharacteristics.LENS_FACING_BACK && cameraCharacteristics.get(
//                            CameraCharacteristics.FLASH_INFO_AVAILABLE
//                        )!!
//                    ) {
//                        mCameraId = camID
//                    }
//                }
//                if (mCameraId != "") {
//                    mCameraManager.get
//                    mCameraManager.setTorchMode(mCameraId, true)
//                }
//            } catch (e: CameraAccessException) {
//                e.printStackTrace()
//            }


        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            val camera = android.hardware.Camera.open()
            val parameters = camera.parameters

            val modes: List<String> = parameters.supportedFlashModes
            when {
                modes.contains(android.hardware.Camera.Parameters.FLASH_MODE_TORCH) -> {
                    parameters.flashMode = android.hardware.Camera.Parameters.FLASH_MODE_TORCH
                }
                modes.contains(android.hardware.Camera.Parameters.FLASH_MODE_ON) -> {
                    parameters.flashMode = android.hardware.Camera.Parameters.FLASH_MODE_ON
                }
                else -> {
                    //No flash available
                }
            }
            camera.parameters = parameters
            isTorchOn = !isTorchOn
//            if (getFlashlightState) {
//                Objects.requireNonNull(camera).startPreview()
//            } else {
//                Objects.requireNonNull(camera).stopPreview()
//            }
        } else {
//            isFlashlightOn()
            if (manager == null) {
                manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
            }
            try {
                manager!!.setTorchMode(cameraId!!, !isTorchOn)
                isTorchOn = !isTorchOn
            } catch (e: CameraAccessException) {
                e.printStackTrace()
            }
        }
    }

    private fun getAppropriateSize(sizes: Array<Size>?): Size {
        // assume sizes is never 0
        if (sizes!!.size == 1) {
            return sizes[0]
        }
        var s = sizes[0]
        val s1 = sizes[1]
        if (s1.width > s.width || s1.height > s.height) {
            // ascending
            if (sensorOrientation % 180 == 0) {
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
            if (sensorOrientation % 180 == 0) {
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