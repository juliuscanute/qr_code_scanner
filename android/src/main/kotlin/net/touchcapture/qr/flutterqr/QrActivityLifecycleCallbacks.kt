package net.touchcapture.qr.flutterqr

import android.app.Activity
import android.app.Application
import android.os.Bundle

class UnRegisterLifecycleCallback(
    private val application: Application,
    private val callback: Application.ActivityLifecycleCallbacks,
) {
    operator fun invoke() = application.unregisterActivityLifecycleCallbacks(callback)
}

fun Activity.registerLifecycleCallbacks(
    onPause: (() -> Unit)? = null,
    onResume: (() -> Unit)? = null,
): UnRegisterLifecycleCallback {
    val callback = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityPaused(p0: Activity) {
            if (p0 == this@registerLifecycleCallbacks) onPause?.invoke()
        }

        override fun onActivityResumed(p0: Activity) {
            if (p0 == this@registerLifecycleCallbacks) onResume?.invoke()
        }

        override fun onActivityStarted(p0: Activity) = Unit

        override fun onActivityDestroyed(p0: Activity) = Unit

        override fun onActivitySaveInstanceState(p0: Activity, p1: Bundle) = Unit

        override fun onActivityStopped(p0: Activity) = Unit

        override fun onActivityCreated(p0: Activity, p1: Bundle?) = Unit
    }

    application.registerActivityLifecycleCallbacks(callback)

    return UnRegisterLifecycleCallback(application, callback)
}
