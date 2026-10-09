# ODYN dependency and reuse audit

## Scope
Candidate repositories discovered in the user's GitHub account; this is not a completed audit of all 588 repositories. Do not copy code before reviewing its license, transitive dependencies and Android build compatibility.

| Repository | Technical role | Decision |
| --- | --- | --- |
| mojealterego/Local-Diffusion | Flutter + native diffusion inspiration | Inspect source and license before porting |
| mojealterego/Stable-Diffusion-KMP | Provider abstraction, gallery, local SDXL | Architecture reference; upstream AGPL-3.0; copying requires license review |
| mojealterego/pocketpal-ai | GGUF import, download and metadata patterns | Reference only; LLM llama.cpp != diffusion GGUF |
| mojealterego/LocalAI | Local API integration | Optional remote/local service adapter |
| mojealterego/ODYN-AI | Agent integration | Optional and isolated |
| mojealterego/hermes-mobile | Mobile agents | Optional and isolated |
| mojealterego/locally-uncensored | Model exploration | Check contents, format, license |
| mojealterego/elevenlabs-android | Audio extension | Not in initial MVP |

## Compatibility rules
1. Do not treat a QNN model as a GGUF model.
2. Do not treat llama.cpp as an image diffusion runtime.
3. Do not claim on-device support because an upstream desktop backend recognizes a model.
4. Keep offline inference separate from remote ComfyUI/LocalAI.
5. Keep original copyright notices and licenses for any imported source.
6. Use Android Storage Access Framework rather than broad storage permissions for model selection.
7. Localize all user-facing strings through ARB, including errors and model import messages.

## Priority
A. Buildable Android Flutter shell and persistent locale.
B. SAF model import, local catalog, integrity checks.
C. stable-diffusion.cpp ARM64 runtime, with actual device tests.
D. QNN isolated adapter and device-specific benchmark.
E. Experimental video backend and remote GPU fallback.

## Validation
No native image or video inference has been demonstrated in this repository. A working APK and S24 Ultra tests remain outstanding.
