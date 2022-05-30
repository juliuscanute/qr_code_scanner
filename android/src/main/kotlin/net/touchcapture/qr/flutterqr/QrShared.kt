package net.touchcapture.qr.flutterqr

import android.annotation.SuppressLint
import android.app.Activity
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

@SuppressLint("StaticFieldLeak")
object QrShared {
    const val CAMERA_REQUEST_ID = 513469796

    var activity: Activity? = null

    var binding: ActivityPluginBinding? = null

}