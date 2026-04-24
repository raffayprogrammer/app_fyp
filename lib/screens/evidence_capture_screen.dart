import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/evidence_service.dart';

class EvidenceCaptureScreen extends StatefulWidget {
  const EvidenceCaptureScreen({super.key});

  @override
  State<EvidenceCaptureScreen> createState() => _EvidenceCaptureScreenState();
}

class _EvidenceCaptureScreenState extends State<EvidenceCaptureScreen>
    with SingleTickerProviderStateMixin {
  final EvidenceService _service = EvidenceService();

  // Animation
  late AnimationController _pulseAnimation;
  late Animation<double> _pulseScale;

  // State
  bool _isInitializing = false;
  bool _isCameraReady = false;
  bool _isRecording = false;
  bool _isSaving = false;
  int _recordingSeconds = 0;
  int _locationPoints = 0;
  Timer? _recordingTimer;

  // Saved evidence list (local files)
  List<Map<String, dynamic>> _savedEvidence = [];

  @override
  void initState() {
    super.initState();

    _pulseAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseAnimation, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseAnimation.dispose();
    _recordingTimer?.cancel();
    _service.disposeCamera();
    super.dispose();
  }

  // ─── INITIALIZE CAMERA ───────────────────────────────────────────────────────
  Future<void> _initializeCamera() async {
    setState(() => _isInitializing = true);

    // Request permissions first
    bool granted = await _service.requestPermissions();

    if (!granted) {
      setState(() => _isInitializing = false);
      _showMessage('Camera and microphone permission required!', Colors.red);
      return;
    }

    // Initialize camera
    await _service.initCamera();

    setState(() {
      _isInitializing = false;
      _isCameraReady = true;
    });
  }

  // ─── START PANIC RECORDING ───────────────────────────────────────────────────
  Future<void> _startRecording() async {
    if (!_isCameraReady) {
      await _initializeCamera();
      if (!_isCameraReady) return;
    }

    // Start video recording
    await _service.startVideoRecording();

    // Start location tracking
    _service.startLocationTracking();

    // Start timer counter
    _recordingSeconds = 0;
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingSeconds++;
          _locationPoints = _service.locationPointsCount;
        });
      }
    });

    setState(() => _isRecording = true);
    _showMessage(
      'Recording started! Audio + Video + Location active',
      Colors.red,
    );
  }

  // ─── STOP AND SAVE ───────────────────────────────────────────────────────────
  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    setState(() {
      _isRecording = false;
      _isSaving = true;
    });

    _showMessage('Saving evidence to your phone...', Colors.orange);

    // Stop video — saves to gallery
    String? videoPath = await _service.stopVideoRecording();

    // Stop location — saves to file
    String? locationPath = await _service.stopLocationTracking();

    // Add to local evidence list
    if (videoPath != null) {
      setState(() {
        _savedEvidence.insert(0, {
          'videoPath': videoPath,
          'locationPath': locationPath ?? 'Not saved',
          'duration': _formatTime(_recordingSeconds),
          'locationPoints': _locationPoints,
          'time': DateTime.now().toString().substring(0, 16),
        });
      });
    }

    // Dispose camera
    await _service.disposeCamera();

    setState(() {
      _isSaving = false;
      _isCameraReady = false;
      _recordingSeconds = 0;
      _locationPoints = 0;
    });

    _showMessage(
      videoPath != null
          ? '✅ Video saved to gallery! Location log saved to phone.'
          : '❌ Save failed. Try again.',
      videoPath != null ? Colors.green : Colors.red,
    );
  }

  // ─── FORMAT TIME ─────────────────────────────────────────────────────────────
  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ─── SHOW SNACKBAR MESSAGE ───────────────────────────────────────────────────
  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── BUILD UI ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evidence Capture'),
        backgroundColor: _isRecording ? Colors.red : const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (_isRecording ? Colors.red : const Color(0xFF2563EB)).withOpacity(
                0.1,
              ),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ── Status Card ──────────────────────────────────────────────
              _buildStatusCard(),

              const SizedBox(height: 20),

              // ── Camera Preview (shown when recording) ────────────────────
              if (_isCameraReady && _service.getCameraPreview() != null)
                _buildCameraPreview(),

              const SizedBox(height: 20),

              // ── PANIC / STOP Button ──────────────────────────────────────
              _buildPanicButton(),

              const SizedBox(height: 20),

              // ── Recording Info (shown when recording) ────────────────────
              if (_isRecording) _buildRecordingInfo(),

              const SizedBox(height: 20),

              // ── Saved Evidence List ──────────────────────────────────────
              _buildSavedEvidenceList(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── STATUS CARD ─────────────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (_isInitializing) {
      statusText = 'Initializing camera...';
      statusColor = Colors.orange;
      statusIcon = Icons.camera_alt;
    } else if (_isSaving) {
      statusText = 'Saving evidence to phone...';
      statusColor = Colors.blue;
      statusIcon = Icons.save;
    } else if (_isRecording) {
      statusText = 'RECORDING ACTIVE — ${_formatTime(_recordingSeconds)}';
      statusColor = Colors.red;
      statusIcon = Icons.fiber_manual_record;
    } else if (_isCameraReady) {
      statusText = 'Camera ready — tap PANIC to record';
      statusColor = Colors.green;
      statusIcon = Icons.videocam;
    } else {
      statusText = 'Tap PANIC to start evidence capture';
      statusColor = Colors.grey;
      statusIcon = Iconsax.security;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, color: statusColor, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evidence Status',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  (_isInitializing || _isSaving)
                      ? const LinearProgressIndicator()
                      : Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CAMERA PREVIEW ──────────────────────────────────────────────────────────
  Widget _buildCameraPreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(height: 250, child: _service.getCameraPreview()!),
    );
  }

  // ─── PANIC BUTTON ────────────────────────────────────────────────────────────
  Widget _buildPanicButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: (_isRecording || _isSaving || _isInitializing)
              ? 1.0
              : _pulseScale.value,
          child: GestureDetector(
            onTap: (_isSaving || _isInitializing)
                ? null
                : (_isRecording ? _stopRecording : _startRecording),
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isSaving
                    ? Colors.grey
                    : _isRecording
                    ? Colors.green
                    : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color:
                        (_isSaving
                                ? Colors.grey
                                : _isRecording
                                ? Colors.green
                                : Colors.red)
                            .withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isSaving
                        ? Icons.hourglass_top
                        : _isRecording
                        ? Icons.stop
                        : Icons.videocam,
                    color: Colors.white,
                    size: 55,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isSaving
                        ? 'SAVING'
                        : _isRecording
                        ? 'STOP'
                        : 'PANIC',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    _isSaving
                        ? 'Please wait'
                        : _isRecording
                        ? 'Tap to stop & save'
                        : 'Tap to record',
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── RECORDING INFO ───────────────────────────────────────────────────────────
  Widget _buildRecordingInfo() {
    return Card(
      elevation: 4,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Recording in progress',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoTile(
                  Icons.videocam,
                  'Video',
                  'Recording',
                  Colors.red,
                ),
                _buildInfoTile(Icons.mic, 'Audio', 'Active', Colors.blue),
                _buildInfoTile(
                  Icons.location_on,
                  'GPS Points',
                  '$_locationPoints',
                  Colors.green,
                ),
                _buildInfoTile(
                  Icons.timer,
                  'Duration',
                  _formatTime(_recordingSeconds),
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ─── SAVED EVIDENCE LIST ─────────────────────────────────────────────────────
  Widget _buildSavedEvidenceList() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saved Evidence',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_savedEvidence.length} videos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Empty state
            if (_savedEvidence.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Iconsax.video,
                        size: 50,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No evidence captured yet\nTap PANIC to start recording',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Evidence items
            ..._savedEvidence.map((item) => _buildEvidenceItem(item)),
          ],
        ),
      ),
    );
  }

  Widget _buildEvidenceItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.video, color: Colors.red, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panic Evidence Video',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${item['duration']}  •  GPS: ${item['locationPoints']} points',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  item['time'],
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Saved',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
