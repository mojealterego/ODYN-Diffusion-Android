package com.mojealterego.odyn_diffusion_android

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Android endpoint for ODYN's versioned Flutter/native contract.
 *
 * This host deliberately reports unavailable until a compiled and tested
 * native inference backend is installed. Never fabricate generated images.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "odyn.diffusion/native_v1"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(false)
                    "generate" -> result.error(
                        "ENGINE_NOT_INSTALLED",
                        "The native diffusion runtime is not bundled in this build.",
                        null
                    )
                    "cancel" -> result.success(null)
                    else -> result.notImplemented()
                }
            }
    }
}
