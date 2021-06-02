package net.touchcapture.qr.mlkit

internal interface Camera {
    @Throws(MLKitReader.Exception::class)
    fun start()
    fun stop()
    val orientation: Int
    val width: Int
    val height: Int
}
