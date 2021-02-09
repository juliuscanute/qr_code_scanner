package net.touchcapture.qr.flutterqr

import android.app.Activity
import android.content.pm.PackageManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.platform.PlatformViewRegistry

class FlutterQrPlugin : FlutterPlugin, ActivityAware {

    /** Plugin registration embedding v1 */
    companion object {
        @JvmStatic
        fun registerWith(registrar: PluginRegistry.Registrar) {
            FlutterQrPlugin().onAttachedToV1(registrar)
        }
    }

    private fun onAttachedToV1(registrar: PluginRegistry.Registrar) {
        Shared.registrar = registrar
        onAttachedToEngines(registrar.platformViewRegistry(), registrar.messenger(), registrar.activity())
    }

    /** Plugin registration embedding v2 */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngines(flutterPluginBinding.platformViewRegistry, flutterPluginBinding.binaryMessenger, Shared.activity)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    /** Plugin start for both embedding v1 & v2 */
    private fun onAttachedToEngines(platformViewRegistry: PlatformViewRegistry, messenger: BinaryMessenger, activity: Activity?) {
        if (activity != null) {
            Shared.activity = activity
        }
        platformViewRegistry
                .registerViewFactory(
                        "net.touchcapture.qr.flutterqr/qrview", QRViewFactory(messenger))
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        Shared.activity = activityPluginBinding.activity
        Shared.binding = activityPluginBinding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Shared.activity = null
        Shared.binding = null
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        Shared.activity = activityPluginBinding.activity
        Shared.binding = activityPluginBinding
    }

    override fun onDetachedFromActivity() {
        Shared.activity = null
        Shared.binding = null
    }
    

}
