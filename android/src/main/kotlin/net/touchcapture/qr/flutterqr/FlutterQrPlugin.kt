package net.touchcapture.qr.flutterqr

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import net.touchcapture.qr.flutterqr.Shared.activity

class FlutterQrPlugin : FlutterPlugin, ActivityAware {

    /** Plugin registration embedding v2 */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        if (activity != null) {
            activity = activity
        }
        flutterPluginBinding.platformViewRegistry
            .registerViewFactory(
                "net.touchcapture.qr.flutterqr/qrview", QRViewFactory(flutterPluginBinding.binaryMessenger))
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        activity = activityPluginBinding.activity
        Shared.binding = activityPluginBinding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        Shared.binding = null
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        activity = activityPluginBinding.activity
        Shared.binding = activityPluginBinding
    }

    override fun onDetachedFromActivity() {
        activity = null
        Shared.binding = null
    }
    

}
