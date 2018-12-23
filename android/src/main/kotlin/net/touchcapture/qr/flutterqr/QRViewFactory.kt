package net.touchcapture.qr.flutterqr

import android.content.Context
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


class QRViewFactory(private val registrar: PluginRegistry.Registrar) :
        PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, id: Int, obj: Any?): PlatformView {
        return QRView(context, registrar,id)
    }

}