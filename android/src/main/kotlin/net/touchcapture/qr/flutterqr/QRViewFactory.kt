package net.touchcapture.qr.flutterqr

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory


class QRViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: Context?,
        viewId: Int,
        args: Any?
    ): PlatformView {

        @Suppress("UNCHECKED_CAST")
        val params = args as HashMap<String, Any>

        return QRView(
            context = requireNotNull(context),
            id = viewId,
            messenger = messenger,
            params = params
        )
    }
}