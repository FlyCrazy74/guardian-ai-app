# Guardian AI App

This is a Flutter 3.10 Android application named "Guardian AI" designed to monitor four events locally without AI: microphone detecting scream or "help" (via simple >30 dB threshold proxy), accelerometer detecting fall, erratic XYZ motion (struggle), and sending SMS with GPS coordinates via telephony to a user-entered number on trigger. It includes runtime permission requests and is optimized for Firebase Test Lab.

## Project Structure

```
guardian_ai_app/
├── android/ # Android specific files
│   ├── app/
│   │   ├── src/
│   │   │   ├── main/
│   │   │   │   ├── AndroidManifest.xml # Permissions for mic, location, SMS
│   │   │   │   ├── java/
│   │   │   │   │   └── com/example/guardian_ai_app/MainActivity.java
│   │   │   │   └── res/
│   │   │   └── ...
│   └── ...
├── lib/
│   └── main.dart # Main application logic, UI, sensor monitoring, SMS sending
├── test/
│   ├── guardian_test.dart # Widget tests for button toggle and UI
│   └── widget_test.dart # Default Flutter widget test
├── pubspec.yaml # Project dependencies (sensors_plus, flutter_sound, telephony, geolocator, permission_handler)
├── build_apk.ps1 # PowerShell script to build the APK
└── README.md # This file
```

## Dependencies

The `pubspec.yaml` file includes the following dependencies:
- `sensors_plus`: For accelerometer data.
- `flutter_sound`: For microphone input and decibel monitoring.
- `telephony`: For sending SMS messages.
- `geolocator`: For obtaining GPS coordinates.
- `permission_handler`: For managing runtime permissions.

## Building the APK

To build the Android APK for release, navigate to the project root directory (`C:\Users\darda\Desktop\Guardian-AI-App\temp_project\guardian_ai_app` in your case) and execute the `build_apk.ps1` PowerShell script. This script will:

1. Clean the Flutter project.
2. Get Flutter dependencies.
3. Build the release APK.

**PowerShell Commands:**

```powershell
# Navigate to the Flutter project directory
Set-Location -Path "C:\Users\darda\Desktop\Guardian-AI-App\temp_project\guardian_ai_app"

# Clean the Flutter project
flutter clean

# Get Flutter dependencies
flutter pub get

# Build the Android APK in release mode
flutter build apk --release

Write-Host "APK build complete. The APK can be found at: build\app\outputs\flutter-apk\app-release.apk"
```

The generated APK will be located at `build/app/outputs/flutter-apk/app-release.apk` relative to your project root.

## Firebase Test Lab Setup (Spark Plan)

Firebase Test Lab allows you to test your app on a wide range of physical devices and virtual devices. For this application, we will focus on instrumentation tests (using `guardian_test.dart`) and Robo tests.

### Prerequisites
1.  **Google Cloud SDK (gcloud CLI) installed and authenticated:** Ensure you have `gcloud` installed and configured with your Google Cloud project.
    ```bash
    gcloud init
    gcloud auth application-default login
    ```
2.  **Firebase project:** Link your Firebase project to your Google Cloud project.

### 1. Build the Application APK
Follow the instructions in the 

`Building the APK` section above to generate your `app-release.apk`.

### 2. Build the Test APK

Flutter currently does not directly support generating a separate instrumentation test APK for `flutter_test` files. `flutter_test` runs on the Dart VM on your development machine, not on an Android device. To run UI tests on Firebase Test Lab, you would typically write Android-specific instrumentation tests (e.g., using Espresso) or use a framework that generates Android instrumentation tests from your Flutter tests (which is not directly supported by `flutter_test`).

However, for basic UI testing on Firebase Test Lab, you can leverage **Robo tests** or write native Android instrumentation tests. For the purpose of verifying the button toggle and basic UI as requested, we will assume you would use Robo tests or convert your `flutter_test` into a native Android instrumentation test. Since the request specifically mentioned `test/guardian_test.dart`, we will outline how to run an instrumentation test if you were to convert it.

**If you were to create an Android Instrumentation Test (e.g., using Espresso) for `guardian_test.dart`'s logic, you would typically build it like this (this is a conceptual step as Flutter's `flutter_test` is not directly convertible to an Android instrumentation APK):**

```bash
# Navigate to the Android project directory
cd android

# Build the test APK (this assumes you have an instrumentation test module setup)
./gradlew assembleAndroidTest
```

This would generate a test APK, typically found at `app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk`.

### 3. Upload and Run Tests on Firebase Test Lab

**For Instrumentation Testing (if you had a separate test APK):**

```bash
# Replace <PROJECT_ID> with your Firebase project ID
gcloud firebase test android run \
  --type instrumentation \
  --app build/app/outputs/flutter-apk/app-release.apk \
  --test app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk \
  --device model=Pixel5,version=31,locale=en,orientation=portrait \
  --timeout 5m
```

**For Robo Testing (recommended for basic UI exploration without a separate test APK):**

Robo tests automatically crawl your app's UI, looking for crashes and other issues. This is a good way to verify basic UI functionality and button toggles without writing specific instrumentation tests.

```bash
# Replace <PROJECT_ID> with your Firebase project ID
gcloud firebase test android run \
  --type robo \
  --app build/app/outputs/flutter-apk/app-release.apk \
  --device model=Pixel5,version=31,locale=en,orientation=portrait \
  --timeout 5m
```

**Target Devices:**

For the Spark plan, you can specify various devices. The example above uses `model=Pixel5,version=31`. You can choose other available models and Android API versions (e.g., `version=36.1` as requested, though API 31 is more commonly available for a wider range of physical devices on Test Lab).

### Emulator Limitations for Sensors

It's important to note that emulators often have limitations in accurately simulating real-world sensor data (accelerometer, microphone, GPS). While some emulators offer basic sensor simulation, they may not fully replicate the nuances of physical device sensors, especially for events like falls or erratic motion. Therefore, for thorough testing of sensor-dependent features, testing on physical devices via Firebase Test Lab is crucial. The microphone threshold detection will also be difficult to test accurately on emulators.

## Project Files

- `lib/main.dart`: Contains the main Flutter application code, UI, permission handling, sensor monitoring logic (accelerometer for fall/erratic motion, microphone for sound), and SMS sending functionality.
- `test/guardian_test.dart`: Contains widget tests to verify the UI behavior, specifically the button toggle and the presence of the phone number input field.
- `android/app/src/main/AndroidManifest.xml`: Updated with necessary permissions for `RECORD_AUDIO`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `SEND_SMS`, and `FOREGROUND_SERVICE`.
- `pubspec.yaml`: Lists all required Flutter dependencies.
- `build_apk.ps1`: PowerShell script for building the release APK.

This completes the Guardian AI app project. Please follow the instructions to build and test your application.

