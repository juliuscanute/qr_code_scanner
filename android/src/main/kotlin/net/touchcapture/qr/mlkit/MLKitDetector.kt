package net.touchcapture.qr.mlkit

import android.util.Log
import androidx.annotation.GuardedBy
import com.google.android.gms.tasks.OnFailureListener
import com.google.android.gms.tasks.OnSuccessListener
import com.google.mlkit.vision.barcode.Barcode
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.common.InputImage

/**
 * Allows Camera classes to send frames to a Detector
 */
internal class MLKitDetector(
    private val communicator: MLKitCallbacks,
    options: BarcodeScannerOptions
) : OnSuccessListener<List<Barcode>>,
    OnFailureListener {
    private val detector: BarcodeScanner = BarcodeScanning.getClient(options)

    interface Frame {
        fun toImage(): InputImage
        fun close()
    }

    @GuardedBy("this")
    private var latestFrame: Frame? = null

    @GuardedBy("this")
    private var processingFrame: Frame? = null
    fun detect(frame: Frame?) {
        if (latestFrame != null) latestFrame!!.close()
        latestFrame = frame
        if (processingFrame == null) {
            processLatest()
        }
    }

    @Synchronized
    private fun processLatest() {
        if (processingFrame != null) processingFrame!!.close()
        processingFrame = latestFrame
        latestFrame = null
        if (processingFrame != null) {
            processFrame(processingFrame!!)
        }
    }

    private fun processFrame(frame: Frame) {
        val image: InputImage = try {
            frame.toImage()
        } catch (ex: IllegalStateException) {
            // ignore state exception from making frame to image
            // as the image may be closed already.
            return
        }
        detector.process(image)
            .addOnSuccessListener(this)
            .addOnFailureListener(this)
    }

    override fun onSuccess(mlkitVisionBarcodes: List<Barcode>) {
        for (barcode in mlkitVisionBarcodes) {
            communicator.qrRead(barcode)
        }
        processLatest()
    }

    override fun onFailure(e: Exception) {
        Log.w(TAG, "MLKit Reading Failure: ", e)
    }

    companion object {
        private const val TAG = "qr.mlkit.detector"
    }

}
