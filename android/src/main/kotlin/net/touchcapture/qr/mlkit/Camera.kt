package net.touchcapture.qr.mlkit

internal interface Camera {
    @Throws(MLKitReader.Exception::class)
    fun start(params: HashMap<String, Any>)
    fun stop()
//    fun flip()
    val orientation: Int
    val width: Int
    val height: Int
}
