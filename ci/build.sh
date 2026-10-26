#!/usr/bin/env bash
# GitHub Actions에서 APK를 굽는 스크립트
set -euxo pipefail
flutter --version
flutter create --org com.renang --project-name renyang_musics --platforms android .
cp ci/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
rm -rf android/app/src/main/kotlin
mkdir -p android/app/src/main/kotlin/com/renang/renyang_musics
cp ci/MainActivity.kt android/app/src/main/kotlin/com/renang/renyang_musics/MainActivity.kt
flutter pub get
dart run flutter_launcher_icons
flutter analyze --no-fatal-infos --no-fatal-warnings || true
flutter build apk --release
cp build/app/outputs/flutter-apk/app-release.apk renyang-musics.apk
