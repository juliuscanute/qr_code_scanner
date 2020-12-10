package net.touchcapture.qr.flutterqr

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar


class FlutterQrPlugin : FlutterPlugin, MethodCallHandler {

    /** Plugin registration embedding v1 */
    companion object {
        @JvmStatic
        fun registerWith(registrar: Registrar) {
            FlutterQrPlugin().onAttachedToEngine(registrar)
        }
    }

    /** Plugin registration embedding v2 */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(flutterPluginBinding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    private fun onAttachedToEngine(registrar: Registrar) {
        registrar
                .platformViewRegistry()
                .registerViewFactory(
                        "net.touchcapture.qr.flutterqr/qrview", QRViewFactory(registrar))
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
            else -> result.notImplemented()
        }
    }
}
