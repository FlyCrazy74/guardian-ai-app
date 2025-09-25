## Todo List

### Phase 1: Set up Flutter project structure and dependencies
- [x] Create a new Flutter project named 'guardian_ai_app'
- [x] Update pubspec.yaml with specified dependencies: sensors_plus, flutter_sound, telephony, geolocator, permission_handler
- [x] Verify Flutter and Dart versions

### Phase 2: Implement core app functionality and sensor monitoring
- [x] Implement UI with phone number input and 'Activate Safe Zone' button
- [x] Implement runtime permission requests for mic, location, SMS
- [x] Implement microphone monitoring for scream/help (>30 dB threshold)
- [x] Implement accelerometer monitoring for fall (>2g spike then <0.5g Z-axis for 3s, with debouncing)
- [x] Implement accelerometer monitoring for erratic XYZ motion (>0.8g variance over short window)
- [x] Implement SMS sending with GPS coords via telephony on trigger
- [x] Handle noisy sensor data with filtering

### Phase 3: Create test files and Firebase Test Lab configuration
- [x] Create test/guardian_test.dart for button toggle and basic UI verification
- [x] Outline Firebase Test Lab configuration for instrumentation/Robo testing

### Phase 4: Generate build scripts and comprehensive documentation
- [x] Generate PowerShell commands for building APK
- [x] Document full project structure
- [x] Document step-by-step instructions for uploading APK and test script to Firebase Test Lab

### Phase 5: Deliver complete project with instructions
- [ ] Present all generated files and instructions to the user

