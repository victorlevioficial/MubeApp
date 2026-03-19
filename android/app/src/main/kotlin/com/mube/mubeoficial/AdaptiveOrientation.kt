package com.mube.mubeoficial

import android.app.Activity
import android.content.pm.ActivityInfo
import android.os.Build
import kotlin.math.min

private const val LARGE_SCREEN_BREAKPOINT_DP = 600f

internal fun Activity.updateOrientationForWindowSize() {
    val targetOrientation =
        if (isCompactWindow()) {
            ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
        } else {
            ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
        }

    if (requestedOrientation != targetOrientation) {
        requestedOrientation = targetOrientation
    }
}

private fun Activity.isCompactWindow(): Boolean {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
        val density = resources.displayMetrics.density
        val bounds = windowManager.currentWindowMetrics.bounds
        val smallestWindowDp = min(bounds.width(), bounds.height()) / density
        return smallestWindowDp < LARGE_SCREEN_BREAKPOINT_DP
    }

    return resources.configuration.smallestScreenWidthDp <
        LARGE_SCREEN_BREAKPOINT_DP
}
