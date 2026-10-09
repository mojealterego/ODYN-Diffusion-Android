# GitHub inventory audit — 2026-10-09

## Coverage and method
GitHub repository search `user:mojealterego`, six pages (100,100,100,100,100,88), returned **588 entries**. Repository-name inventory complete at query time. Source inspection is **not** complete for 588 projects: README content was inspected for 14 high-signal repositories. Names alone are only discovery signals. Duplicate names appeared across pages; counts refer to returned entries and require deduplication by repository ID for a unique count.

## Direct reuse candidates — inspected README

| Repository | Verified README claims | ODYN integration decision |
| --- | --- | --- |
| Local-Diffusion | Flutter Android app powered by stable-diffusion.cpp; SD1.x, SDXL, Flux, model download, quantization | **P0**: inspect lib/, android/, native bridge and LICENSE; primary local Android reference |
| stable-diffusion.cpp | C/C++ inference for SD, Flux, Wan; README announces FLUX.2 Klein and Qwen Image 2.1 | **P0**: pin revision, inspect headers, build ARM64, verify API and runtime; do not assume mobile support |
| local-dream | Snapdragon NPU SDXL support from 8 Gen 3; QNN SDK and MNN | **P1**: inspect QNN binary and model licensing, isolate NPU backend |
| Android-AI-Studio | Kotlin Compose Android -> authenticated FastAPI -> private ComfyUI; jobs, cancellation, media export, progress | **P1**: remote mode API reference, not local inference |
| Stable-Diffusion-KMP | Android/iOS AI image client, remote providers and platform-specific local inference | **P1**: UX/provider reference; review license before code reuse |
| Resolver-Stable-Diffusion-Client-for-android | Android Forge/ComfyUI client, dynamic workflow parameters, background tasks | **P2**: remote workflow UX; GPLv3 license needs review |
| Uncensored-Local-Studio | Offline desktop image, LLM, STT, TTS, Windows/Linux/macOS | **P2**: desktop backend/API ideas, not Android-native engine |
| Uncensored-Local-AI-Multiplatform | Flutter mobile-first local LLM app | **P2**: Flutter settings/model download patterns, not diffusion runtime |
| local-llms-on-android | Local LLM with downloadable model management, image/voice inputs | **P2**: UX/model lifecycle patterns only |
| ComfyUI-LTXVideo | ComfyUI custom nodes for LTX; README requests CUDA GPU 32GB+ VRAM | **P2 remote only**: cannot claim S24 Ultra compatibility |
| LTX-Video | Video inference and newer LTX-2 ecosystem | **P2 remote**: inspect license and hardware requirements |
| HunyuanVideo-I2V | Image-to-video framework | **P2 remote**: separate GPU backend |
| InvokeAI | Desktop/server creative image engine and workflows | **P2 remote**: provider/workflow inspiration |

## Additional names discovered in 588-entry inventory (not source-audited)
- **Image/video:** Stable-Diffusion, Stable-Diffusion-3.5-Web-UI, stable-diffusion-webui, Text2Image-Generation, MaxVideoAi, agnes-ai-video-suite, Text-To-Video-API, OpenMontage, OmniVideoBench, OmniVideo-100K, HunyuanPortraitLCM, Open-Generative-AI, ComfyUI-audio.
- **Android/mobile:** Android, flutter, compose-multiplatform, expo, mobile-mcp, mobile-use, PhoneClaw, Codex-Android, Agent-Android, Duix-Mobile, mini-mobile-7, gpt_mobile.
- **Model/runtime:** llama.cpp, ollama, LocalAI, pocketpal-ai, Llamatik, transformers, localmind, OpenLLM.
- **Automation/agents:** ODYN-AI, hermes-mobile, Agent-God-Level-Omega, agenticSeek, agent-command-center-sdk, open-agent-platform, MCP-Server-Eleven-Labs.

## Architectural recommendation
1. **Local path:** Flutter UI -> typed Dart engine interface -> JNI/FFI native Android bridge -> stable-diffusion.cpp ARM64. First validate SD1.5 and SDXL with a small licensed model.
2. **NPU path:** separate QNN adapter. QNN assets are not GGUF. Validate Qualcomm SDK redistribution and actual S24 Ultra benchmark.
3. **Remote path:** authenticated ComfyUI/FastAPI adapter modeled on Android-AI-Studio. Explicit network mode and clear consent.
4. **Video:** first benchmark Wan 2.1 1.3B with peak RAM and thermal telemetry; large LTX/Hunyuan workflows remain remote-first.
5. **Localization:** all new user-visible text in ARB; Polish must remain available offline; persist language selection.
6. **Licensing:** track original project, revision, license and attribution before copying; do not merge GPL/AGPL sources blindly into Apache/MIT modules.

## Immediate blocking items
- ODYN repository still lacks generated Flutter Android host/Gradle scaffolding.
- No compiled JNI/FFI stable-diffusion.cpp library or actual generation evidence.
- No device measurements, APK, or verified CI success.
- Full source-level audit of the remaining repos is pending; do not report it as completed.
