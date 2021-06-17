package net.touchcapture.qr.mlkit

import com.google.mlkit.vision.barcode.Barcode

interface MLKitCallbacks {
    fun qrRead(barcode: Barcode)
}
