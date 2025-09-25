import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:telephony/telephony.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GuardianHomePage(),
    );
  }
}

class GuardianHomePage extends StatefulWidget {
  const GuardianHomePage({super.key});

  @override
  State<GuardianHomePage> createState() => _GuardianHomePageState();
}

class _GuardianHomePageState extends State<GuardianHomePage> {
  final TextEditingController _phoneNumberController = TextEditingController();
  bool _isSafeZoneActive = false;
  Color _buttonColor = Colors.red;

  // Sensor monitoring variables
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  FlutterSoundRecorder? _audioRecorder;
  final Telephony telephony = Telephony.instance;

  // Fall detection variables
  List<double> _accelerometerZHistory = [];
  static const int _fallDetectionWindow = 60; // Number of samples for fall detection (e.g., 60 samples for 3 seconds at 20Hz)
  static const double _fallThresholdG = 2.0; // G-force spike for fall
  static const double _postFallThresholdG = 0.5; // Z-axis G-force after fall
  bool _fallDetected = false;

  // Erratic motion detection variables
  List<AccelerometerEvent> _accelerometerWindow = [];
  static const int _erraticMotionWindowSize = 20; // Number of samples for erratic motion (e.g., 1 second at 20Hz)
  static const double _erraticMotionVarianceThreshold = 0.8; // Variance threshold for erratic motion

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initAudioRecorder();
  }

  Future<void> _initAudioRecorder() async {
    await _audioRecorder!.openRecorder();
    _audioRecorder!.setSubscriptionDuration(const Duration(milliseconds: 50)); // Get audio levels frequently
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _audioRecorder!.closeRecorder();
    _audioRecorder = null;
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.locationWhenInUse,
      Permission.sms,
    ].request();

    if (statuses[Permission.microphone]!.isDenied ||
        statuses[Permission.locationWhenInUse]!.isDenied ||
        statuses[Permission.sms]!.isDenied) {
      _showPermissionDeniedDialog();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Denied'),
          content: const Text('Please grant microphone, location, and SMS permissions to use this app.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // Opens app settings for user to grant permissions
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleSafeZone() async {
    if (!_isSafeZoneActive) {
      await _requestPermissions();
      if (await Permission.microphone.isGranted &&
          await Permission.locationWhenInUse.isGranted &&
          await Permission.sms.isGranted) {
        _startMonitoring();
        setState(() {
          _isSafeZoneActive = true;
          _buttonColor = Colors.green;
        });
      } else {
        // Permissions not granted, do not activate
        _showPermissionDeniedDialog();
      }
    } else {
      _stopMonitoring();
      setState(() {
        _isSafeZoneActive = false;
        _buttonColor = Colors.red;
      });
    }
  }

  void _startMonitoring() async {
    // Start accelerometer monitoring
    _accelerometerSubscription = accelerometerEventStream(samplingPeriod: const Duration(milliseconds: 50)).listen((AccelerometerEvent event) {
      _handleAccelerometerEvent(event);
    });

    // Start audio monitoring
    await _audioRecorder!.startRecorder(toFile: 'audio_temp.aac', codec: Codec.aac);
    _audioRecorder!.onProgress!.listen((e) {
      if (e.decibels != null && e.decibels! > -30.0) { // -30 dB is a proxy for >30 dB threshold
        _triggerAlert('Scream/Help detected!');
      }
    });
  }

  void _stopMonitoring() {
    _accelerometerSubscription?.cancel();
    _audioRecorder!.stopRecorder();
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Fall detection
    _accelerometerZHistory.add(event.z);
    if (_accelerometerZHistory.length > _fallDetectionWindow) {
      _accelerometerZHistory.removeAt(0);
    }

    double totalAcceleration = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

    if (!_fallDetected && totalAcceleration > _fallThresholdG) {
      // Potential fall detected, check for post-fall state
      Timer(const Duration(seconds: 3), () {
        if (_accelerometerZHistory.isNotEmpty && _accelerometerZHistory.last < _postFallThresholdG) {
          _fallDetected = true; // Debounce
          _triggerAlert('Fall detected!');
          Timer(const Duration(seconds: 10), () => _fallDetected = false); // Reset debounce after 10 seconds
        }
      });
    }

    // Erratic motion detection
    _accelerometerWindow.add(event);
    if (_accelerometerWindow.length > _erraticMotionWindowSize) {
      _accelerometerWindow.removeAt(0);
    }

    if (_accelerometerWindow.length == _erraticMotionWindowSize) {
      double varianceX = _calculateVariance(_accelerometerWindow.map((e) => e.x).toList());
      double varianceY = _calculateVariance(_accelerometerWindow.map((e) => e.y).toList());
      double varianceZ = _calculateVariance(_accelerometerWindow.map((e) => e.z).toList());

      if (varianceX > _erraticMotionVarianceThreshold ||
          varianceY > _erraticMotionVarianceThreshold ||
          varianceZ > _erraticMotionVarianceThreshold) {
        _triggerAlert('Erratic motion detected (struggle)!');
      }
    }
  }

  double _calculateVariance(List<double> data) {
    if (data.isEmpty) return 0.0;
    double mean = data.reduce((a, b) => a + b) / data.length;
    double variance = data.map((e) => pow(e - mean, 2)).reduce((a, b) => a + b) / data.length;
    return variance;
  }

  Future<void> _triggerAlert(String message) async {
    if (_phoneNumberController.text.isEmpty) {
      _showSnackBar('Please enter a phone number to send alerts.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String smsMessage = '$message\nGPS: ${position.latitude}, ${position.longitude}';

    try {
      await telephony.sendSms(
        to: _phoneNumberController.text,
        message: smsMessage,
      );
      _showSnackBar('Alert sent: $message');
    } catch (e) {
      _showSnackBar('Failed to send SMS: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian AI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Emergency Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleSafeZone,
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor, // Use _buttonColor here
                minimumSize: const Size(double.infinity, 80), // Make button large
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                _isSafeZoneActive ? 'Deactivate Safe Zone' : 'Activate Safe Zone',
                style: const TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
