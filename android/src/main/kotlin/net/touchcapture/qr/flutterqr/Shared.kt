package net.touchcapture.qr.flutterqr

import android.app.Activity
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry

object Shared {
    const val CAMERA_REQUEST_ID = 513469796
    var activity: Activity? = null
    var binding: ActivityPluginBinding? = null
}