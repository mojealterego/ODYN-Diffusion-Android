package com.mojealterego.odyn_diffusion_android

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val channelName = "odyn.diffusion/native_v1"
    private val worker = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var loaded = false

    private external fun nativeLibraryLoaded(): Boolean
    private external fun nativeGenerateImage(
        modelPath: String, prompt: String, width: Int, height: Int,
        steps: Int, seed: Long, outputPath: String
    ): String?
    private external fun nativeCancel()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        loaded = try {
            System.loadLibrary("odyn_native")
            nativeLibraryLoaded()
        } catch (_: UnsatisfiedLinkError) {
            false
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAvailable" -> result.success(loaded)
                    "generate" -> {
                        if (!loaded) {
                            result.error("ENGINE_NOT_INSTALLED", "Native diffusion runtime unavailable", null)
                        } else {
                            val model = call.argument<String>("modelPath")
                            val prompt = call.argument<String>("prompt")
                            val width = call.argument<Int>("width") ?: 512
                            val height = call.argument<Int>("height") ?: 512
                            val steps = call.argument<Int>("steps") ?: 20
                            val frames = call.argument<Int>("frames") ?: 1
                            val seed = call.argument<Long>("seed") ?: -1L
                            if (model.isNullOrBlank() || prompt.isNullOrBlank() || frames != 1 ||
                                width !in 64..2048 || height !in 64..2048 ||
                                width % 8 != 0 || height % 8 != 0 || steps !in 1..150 ||
                                !File(model).isFile) {
                                result.error("INVALID_REQUEST", "Invalid image request or missing model", null)
                            } else {
                                val output = File(cacheDir, "odyn-${System.nanoTime()}.png")
                                worker.execute {
                                    try {
                                        val path = nativeGenerateImage(model, prompt, width, height, steps, seed, output.absolutePath)
                                        mainHandler.post {
                                            if (path == null) result.error("INFERENCE_FAILED", "Image generation failed", null)
                                            else result.success(path)
                                        }
                                    } catch (e: Exception) {
                                        mainHandler.post { result.error("INFERENCE_FAILED", e.message, null) }
                                    }
                                }
                            }
                        }
                    }
                    "cancel" -> {
                        if (loaded) nativeCancel()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        worker.shutdown()
        super.onDestroy()
    }
}
