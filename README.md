# ODYN Diffusion Android

Android-first local image/video generation project targeting Samsung Galaxy S24 Ultra (Snapdragon 8 Gen 3, Adreno 750).

## Status

Architecture bootstrap only. No working APK or validated model inference yet. Do not treat upstream model support as proof of Android compatibility.

## Intended stack

- Flutter Android UI, Polish localization
- Native C/C++ inference through `stable-diffusion.cpp` with a pinned upstream revision
- Dart FFI bridge for model lifecycle, image generation and video generation
- Import of local GGUF and required companion encoder/VAE assets
- Android arm64-v8a, CPU fallback, GPU acceleration only after device validation
- MP4 export using Android MediaCodec/MediaMuxer or a verified equivalent

## Model acceptance matrix

| Family | Target | Status |
| --- | --- | --- |
| SDXL | text-to-image baseline | Not tested |
| FLUX.2 Klein 4B | text-to-image | Not tested |
| Qwen Image 2.1 | text-to-image | Not tested; memory risk |
| Wan 2.1 1.3B | text-to-video | Not tested; runtime and memory risk |

## Implementation gates

1. Import and license review of Local Diffusion and stable-diffusion.cpp; pin exact commits and preserve license notices.
2. Reproducible Flutter/NDK arm64 build and CI artifact.
3. Native bridge with typed capability checks, cancellation, resource cleanup and bounded memory.
4. Local model registry with SHA-256 verification, companion assets and import validation.
5. Polish UI for image, video, models and settings.
6. Unit/integration tests, then physical S24 Ultra profiling (peak RSS, latency, temperature, successful image/video export).

## References

- https://github.com/rmatif/Local-Diffusion
- https://github.com/leejet/stable-diffusion.cpp

## Security

No arbitrary model execution, no remote telemetry by default. Model weights must be acquired under their respective licenses. Avoid committing large model files to Git.
