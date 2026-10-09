# ODYN Diffusion Android — implementation plan

## Baseline

Target: Samsung Galaxy S24 Ultra, Android ARM64, Snapdragon 8 Gen 3. Repository initially contains only architecture documentation. Upstream Local Diffusion is Apache-2.0; preserve license and attribution when importing its code. Do not change upstream or default branch without an explicit migration plan.

## Phase A — reproducible source baseline

1. Import upstream `rmatif/Local-Diffusion` with source history/license provenance recorded in `UPSTREAM.md`.
2. Pin Flutter, Gradle, Android NDK, Dart packages and native `stable-diffusion.cpp` commit; record SHA values and dependency licenses.
3. Build original baseline without model changes, capture APK checksum, run Flutter analyzer and tests.
4. Add CI for arm64-v8a APK and publish only successful build artifacts.

**Gate:** repeatable build from clean checkout; existing SDXL image generation verified on actual device.

## Phase B — typed native inference bridge

1. Audit current Dart FFI bindings against pinned C header, including ownership, thread affinity, callback lifetimes and cancellation.
2. Introduce typed image/video generation requests and capability detection; never guess architecture from filename alone.
3. Ensure model unload and error paths free native memory; isolate long-running inference from UI.
4. Add tests for invalid paths, missing companion assets, unsupported model families, cancellation and low-memory errors.

**Gate:** bridge compiles against pinned native library and tests pass.

## Phase C — model registry

1. User-initiated SAF import of GGUF/safetensors; persist URI grants where supported.
2. Validate readable file, magic bytes, model metadata and companion encoder/VAE paths; compute SHA-256 in streaming chunks.
3. Record license/source/quantization/architecture/capabilities separately from user-entered labels.
4. Support offline usage; no implicit model downloads or telemetry.

**Gate:** repeatable imports and deterministic validation failures.

## Phase D — model-specific integration

- SDXL: reference baseline.
- FLUX.2 Klein 4B: verify correct diffusion, text encoder and VAE loading and memory budget.
- Qwen Image 2.1: validate encoder/VAE and abort safely on memory pressure.
- Wan 2.1 1.3B: use native video-generation API, bounded frames, cancellation, and Android MP4 encoding.

**Gate:** each model passes actual S24 Ultra end-to-end generation with peak RSS, elapsed time and output inspection logged. Library support alone does not satisfy this gate.

## Phase E — Polish UI

Tabs: Obraz, Wideo, Modele, Ustawienia. Display exact loaded assets, capability, estimated memory risk and generation status. Provide accessibility labels, error details, cancel control and explicit storage destination.

## Security and distribution

- Do not execute code supplied by model archives.
- Reject untrusted remote URLs by default; user explicitly approves downloads.
- Enforce bounded dimensions/frame counts and free disk checks.
- Preserve all upstream notices; verify redistributed model licenses individually.
- Never commit model weights, secrets, signing keys or device identifiers.

## Open validation items

- Actual GPU backend performance on Adreno 750.
- Current upstream API/ABI stability.
- Wan runtime memory usage and MP4 encoder compatibility.
- Qwen Image 2.1 feasibility with 12 GB shared RAM.

No functional APK is claimed until the gates pass.
