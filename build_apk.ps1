# Build APK Script for Guardian AI App
# This script builds the release APK using Flutter

cd "$PSScriptRoot"

flutter clean
flutter pub get
flutter build apk --release

Write-Host "`n[?] APK build complete. You can find it here: .\build\app\outputs\flutter-apk\app-release.apk"
