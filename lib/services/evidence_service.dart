import 'dart:io';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:flutter/material.dart';

class EvidenceService {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  bool _isRecordingVideo = false;
  bool _isTrackingLocation = false;

  XFile? _recordedVideo;
  List<Map<String, dynamic>> _locationPoints = [];
  Timer? _locationTimer;

  // ─── REQUEST PERMISSIONS ─────────────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
    await Permission.location.request();
    await Permission.storage.request();
    await Permission.notification.request();

    final cameraGranted = await Permission.camera.isGranted;
    final micGranted = await Permission.microphone.isGranted;
    final locationGranted = await Permission.location.isGranted;

    return cameraGranted && micGranted && locationGranted;
  }

  // ─── FOREGROUND SERVICE (keeps process alive when screen is off) ─────────────
  Future<void> _startForegroundService() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'evidence_recording',
        channelName: 'Evidence Recording',
        channelDescription:
            'SafetyGuardian is recording evidence in the background',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      notificationTitle: 'SafetyGuardian — Recording',
      notificationText: 'Evidence is being recorded. Tap to return.',
    );
  }

  Future<void> _stopForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
  }

  // ─── INITIALIZE CAMERA ───────────────────────────────────────────────────────
  Future<void> initCamera() async {
    _cameras = await availableCameras();

    // Use back camera
    CameraDescription backCamera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: true, // audio recorded with video
    );

    await _cameraController!.initialize();
  }

  // ─── START VIDEO RECORDING ───────────────────────────────────────────────────
  Future<void> startVideoRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      await _startForegroundService();
      await _cameraController!.startVideoRecording();
      _isRecordingVideo = true;
    } catch (e) {
      print('Start recording error: $e');
      await _stopForegroundService();
    }
  }

  // ─── STOP VIDEO RECORDING ────────────────────────────────────────────────────
  Future<String?> stopVideoRecording() async {
    if (!_isRecordingVideo || _cameraController == null) return null;

    try {
      // Stop recording — returns the video file
      _recordedVideo = await _cameraController!.stopVideoRecording();
      _isRecordingVideo = false;
      await _stopForegroundService();

      // Save video to phone gallery
      final result = await SaverGallery.saveFile(
        filePath: _recordedVideo!.path,
        fileName: 'panic_${DateTime.now().millisecondsSinceEpoch}.mp4',
        androidRelativePath: 'Movies/SafetyGuardian',
        skipIfExists: false,
      );

      if (result.isSuccess) {
        print('✅ Video saved to gallery');
        return _recordedVideo!.path;
      } else {
        print('❌ Gallery save failed');
        return _recordedVideo!.path; // return path anyway
      }
    } catch (e) {
      print('Stop recording error: $e');
      await _stopForegroundService();
      return null;
    }
  }

  // ─── START LOCATION TRACKING ─────────────────────────────────────────────────
  void startLocationTracking() {
    _isTrackingLocation = true;
    _locationPoints.clear();

    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isTrackingLocation) {
        timer.cancel();
        return;
      }
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _locationPoints.add({
          'lat': position.latitude,
          'lng': position.longitude,
          'time': DateTime.now().toIso8601String(),
        });
        print('📍 ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('Location error: $e');
      }
    });
  }

  // ─── STOP LOCATION TRACKING ──────────────────────────────────────────────────
  Future<String?> stopLocationTracking() async {
    _isTrackingLocation = false;
    _locationTimer?.cancel();

    if (_locationPoints.isEmpty) return null;

    try {
      // Save location data as text file on phone
      final directory = await getExternalStorageDirectory();
      final folder = Directory('${directory!.path}/SafetyGuardian');
      if (!await folder.exists()) {
        await folder.create(recursive: true);
      }

      final fileName =
          'location_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${folder.path}/$fileName');

      // Write each location point
      String content = 'SafetyGuardian Evidence - Location Log\n';
      content += 'Captured: ${DateTime.now()}\n\n';
      for (var point in _locationPoints) {
        content +=
            'Time: ${point['time']}\nLat: ${point['lat']}, Lng: ${point['lng']}\n\n';
      }

      await file.writeAsString(content);
      print('📍 Location saved: ${file.path}');
      return file.path;
    } catch (e) {
      print('Save location error: $e');
      return null;
    }
  }

  // ─── GET CAMERA PREVIEW WIDGET ───────────────────────────────────────────────
  Widget? getCameraPreview() {
    if (_cameraController != null &&
        _cameraController!.value.isInitialized) {
      return CameraPreview(_cameraController!);
    }
    return null;
  }

  // ─── DISPOSE CAMERA ──────────────────────────────────────────────────────────
  Future<void> disposeCamera() async {
    await _cameraController?.dispose();
    _cameraController = null;
  }

  // ─── GETTERS ─────────────────────────────────────────────────────────────────
  bool get isRecording => _isRecordingVideo;
  int get locationPointsCount => _locationPoints.length;
  CameraController? get cameraController => _cameraController;
}