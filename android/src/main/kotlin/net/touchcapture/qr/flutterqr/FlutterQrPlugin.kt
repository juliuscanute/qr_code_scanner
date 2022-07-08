package net.touchcapture.qr.flutterqr

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class FlutterQrPlugin : FlutterPlugin, ActivityAware {

    /** Plugin registration embedding v2 */
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        flutterPluginBinding.platformViewRegistry
            .registerViewFactory(
                VIEW_TYPE_ID,
                QRViewFactory(flutterPluginBinding.binaryMessenger)
            )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        // Leave empty
        // Nullifying QrShared.activity and QrShared.binding here will cause errors if plugin is detached by another plugin
    }

    override fun onAttachedToActivity(activityPluginBinding: ActivityPluginBinding) {
        QrShared.activity = activityPluginBinding.activity
        QrShared.binding = activityPluginBinding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        QrShared.activity = null
        QrShared.binding = null
    }

    override fun onReattachedToActivityForConfigChanges(activityPluginBinding: ActivityPluginBinding) {
        QrShared.activity = activityPluginBinding.activity
        QrShared.binding = activityPluginBinding
    }

    override fun onDetachedFromActivity() {
        QrShared.activity = null
        QrShared.binding = null
    }

    companion object {
        private const val VIEW_TYPE_ID = "net.touchcapture.qr.flutterqr/qrview"
    }
}
