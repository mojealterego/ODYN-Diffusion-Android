# Aplikacja.pdf — engineering extraction

Source: user-provided 45-page copy of an earlier discussion. Claims are not independently verified.

## Candidate backends

- CPU and Adreno GPU via stable-diffusion.cpp.
- Qualcomm QNN/NPU as a **separate** experimental backend: QNN model files are not interchangeable with GGUF weights. Do not claim support until SDK licensing, runtime, model packaging and device tests are complete.
- Optional remote ComfyUI client is a distinct operating mode and must not be confused with offline inference.

## Prioritized models

1. SD 1.5 and SDXL: first on-device image-generation validation.
2. Qualcomm-targeted SDXL/Illustrious/Pony models: verify exact QNN runtime and SoC compatibility.
3. FLUX.2 Klein: experimental mobile inference.
4. Wan 2.1 1.3B: experimental video; model weight size does not include text encoder, VAE, activation memory or MP4 encoding overhead.
5. Qwen Image 2.1 and LTX Video: experimental; verify actual Android compatibility before enabling.

## Product requirements

- All UI strings in ARB files; Polish and English mandatory; German, Spanish and French initially supported.
- User-controlled model import and no silent network downloads.
- Model format, capability, license, checksum and companion assets tracked explicitly.
- No invented generation success: until native backend is connected, UI must clearly show that generation is unavailable.

## Acceptance tests

- Flutter localization generation and tests pass in CI.
- Actual S24 Ultra generation outputs inspectable images and MP4 files.
- Record peak RAM, time, thermal throttling, failed imports and cancellation behavior.

## Source caveat

The PDF contains model availability, file size and performance assertions without reproducible device measurements. Treat these as research leads, not completed validation.
