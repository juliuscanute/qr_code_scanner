package net.touchcapture.qr.flutterqr

import android.app.Activity
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import io.flutter.view.TextureRegistry

object Shared {
    const val CAMERA_REQUEST_ID = 513469796
    var activity: Activity? = null
    var binding: ActivityPluginBinding? = null
    var registrar: PluginRegistry.Registrar? = null
    var textures: TextureRegistry? = null
    var mlkitChannel: MethodChannel? = null
}