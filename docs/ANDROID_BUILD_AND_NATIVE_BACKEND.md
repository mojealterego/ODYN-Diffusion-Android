# Android build and native backend

## Bootstrap

The repository currently contains Dart/Flutter sources but no checked-in Android host scaffold. From the repository root, using a compatible Flutter SDK:

```sh
flutter create --platforms=android --org com.mojealterego --project-name odyn_diffusion_android .
flutter pub get
flutter gen-l10n
flutter analyze lib test
flutter test
flutter build apk --debug --target-platform android-arm64
```

Do not commit generated files blindly: review AndroidManifest, Gradle, package ID, dependency versions and diffs first. For CI, run the same steps and upload the actual APK artifact only after a successful build.

## Native engine

The Dart channel name is `odyn.diffusion/native_v1` and methods are `isAvailable`, `generate`, `cancel`. Android host must report `isAvailable=false` until a real, loadable inference library is present. `generate` receives prompt, modelPath, width, height, steps, frames and seed and returns an output path. Never return a fabricated image path. Model file must be readable from app-private storage; do not pass SAF content URIs directly to a C++ filesystem loader without staging.

## Release gate

Required evidence: passing analyzer and unit tests, successful ARM64 APK build, device installation, valid local model import, native generation producing a readable PNG, cancellation test, peak RAM/temperature measurements and artifact checksum. These are NOT yet verified.
