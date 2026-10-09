#!/usr/bin/env bash
set -euo pipefail

# Recreate Flutter's Android host without overwriting ODYN's Kotlin channel.
# Run from the repository root with Flutter and Android SDK installed.
cd "$(dirname "$0")/.."
command -v flutter >/dev/null || { echo "Flutter SDK is required" >&2; exit 127; }
test -f pubspec.yaml || { echo "Run from an ODYN source checkout" >&2; exit 2; }

host="android/app/src/main/kotlin/com/mojealterego/odyn_diffusion_android/MainActivity.kt"
if [ -f "$host" ]; then
  cp "$host" /tmp/odyn-mainactivity-$$.kt
  trap 'rm -f /tmp/odyn-mainactivity-$$.kt' EXIT
fi

flutter create --platforms=android --org com.mojealterego --project-name odyn_diffusion_android .
if [ -f /tmp/odyn-mainactivity-$$.kt ]; then
  mkdir -p "$(dirname "$host")"
  cp /tmp/odyn-mainactivity-$$.kt "$host"
fi
python3 - <<'PY'
from pathlib import Path
p = Path("android/app/src/main/AndroidManifest.xml")
manifest = p.read_text()
manifest = manifest.replace('android:name=".MainActivity"', 'android:name="com.mojealterego.odyn_diffusion_android.MainActivity"')
p.write_text(manifest)
PY
if [ ! -f third_party/stable-diffusion.cpp/CMakeLists.txt ]; then
  mkdir -p third_party
  git clone --depth 1 --recurse-submodules https://github.com/mojealterego/stable-diffusion.cpp.git third_party/stable-diffusion.cpp
fi
python3 - <<'PY'
from pathlib import Path
p = Path("android/app/build.gradle.kts")
if not p.exists():
    raise SystemExit("Missing generated Gradle Kotlin script")
s = p.read_text()
anchor = "android {"
if anchor not in s:
    raise SystemExit("Unexpected Gradle layout")
s = s.replace(anchor, """android {
    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }
""", 1)
p.write_text(s)
PY
flutter pub get
flutter gen-l10n
flutter analyze lib test
flutter test
flutter build apk --debug --target-platform android-arm64
printf '\nAPK: %s\n' "build/app/outputs/flutter-apk/app-debug.apk"
sha256sum build/app/outputs/flutter-apk/app-debug.apk
