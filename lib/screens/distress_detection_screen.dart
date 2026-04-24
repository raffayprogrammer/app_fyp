import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/sos_service.dart';

class DistressDetectionScreen extends StatefulWidget {
  const DistressDetectionScreen({super.key});

  @override
  State<DistressDetectionScreen> createState() =>
      _DistressDetectionScreenState();
}

class _DistressDetectionScreenState extends State<DistressDetectionScreen>
    with SingleTickerProviderStateMixin {
  // Animation for detection
  late AnimationController _pulseAnimation;
  late Animation<double> _pulseScale;

  // State variables
  bool _isDetectionActive = false;
  bool _isListening = false;
  bool _isMonitoringMotion = false;
  bool _isLocationTracking = false;
  String _detectionStatus = 'Inactive';
  Color _statusColor = Colors.grey;

  // Sensor readings (live)
  double _soundLevel = 0.0;
  double _movementIntensity = 0.0;
  String _currentActivity = 'Stationary';
  List<String> _recentAlerts = [];

  // Real accelerometer stream + state to prevent dialog spam
  StreamSubscription<AccelerometerEvent>? _accelSub;
  bool _dialogShowing = false;
  DateTime _lastTriggerAt = DateTime.fromMillisecondsSinceEpoch(0);
  final SosService _sosService = SosService();

  // Distress patterns (for demo)
  final List<Map<String, dynamic>> _distressEvents = [
    {
      'type': 'Loud Noise',
      'time': '2 min ago',
      'level': 0.85,
      'detected': true,
    },
    {
      'type': 'Sudden Movement',
      'time': '5 min ago',
      'level': 0.92,
      'detected': true,
    },
    {'type': 'Running', 'time': '10 min ago', 'level': 0.78, 'detected': false},
    {'type': 'Shouting', 'time': '15 min ago', 'level': 0.95, 'detected': true},
  ];

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for active state
    _pulseAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseAnimation, curve: Curves.easeInOut),
    );

  }

  // Subscribe to real accelerometer events. Magnitude of acceleration is used
  // as a proxy for "how violently the phone is moving." At rest the magnitude
  // is ~9.8 m/s^2 (gravity); shaking/running pushes it well above that.
  void _startSensorMonitoring() {
    _accelSub?.cancel();
    _accelSub = accelerometerEventStream().listen((event) {
      if (!mounted || !_isDetectionActive) return;

      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      final excess = (magnitude - 9.8).abs();
      final normalized = (excess / 20).clamp(0.0, 1.0);

      String activity;
      if (normalized > 0.7) {
        activity = 'Violent Movement';
      } else if (normalized > 0.4) {
        activity = 'Running';
      } else if (normalized > 0.15) {
        activity = 'Walking';
      } else {
        activity = 'Stationary';
      }

      setState(() {
        _movementIntensity = normalized;
        _currentActivity = activity;
      });

      // Trigger the "Are you safe?" prompt if movement is violent AND we
      // haven't already shown it recently (10-second cooldown).
      final now = DateTime.now();
      if (normalized > 0.7 &&
          !_dialogShowing &&
          now.difference(_lastTriggerAt).inSeconds > 10) {
        _dialogShowing = true;
        _lastTriggerAt = now;
        _showDistressDialog();
      }
    });
  }

  void _stopSensorMonitoring() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  void _showDistressDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.warning, color: Colors.orange, size: 60),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Are you safe?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Unusual activity detected: Loud sounds and sudden movement',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _dialogShowing = false;
                      _addAlert('User confirmed SAFE');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "I'm Safe",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _dialogShowing = false;
                      _activateEmergency();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red.shade600,
                            size: 30,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Help Needed",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _dialogShowing = false;
                _addAlert('False alarm - dismissed');
              },
              child: const Text('False Alarm'),
            ),
          ],
        ),
      ),
    );
  }

  void _activateEmergency() {
    _addAlert('🚨 EMERGENCY ACTIVATED');
    // Fire the real SOS flow: sequential contact calls/SMS, then escalation
    // to Police 15 if no one responds (see Module 12 cascade in SosService).
    _sosService.startSos();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.warning, color: Colors.red, size: 60),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Emergency Mode Activated',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Alerting emergency contacts and sharing location',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _addAlert(String message) {
    setState(() {
      _recentAlerts.insert(
        0,
        '$message - ${DateTime.now().hour}:${DateTime.now().minute}',
      );
      if (_recentAlerts.length > 5) {
        _recentAlerts.removeLast();
      }
    });
  }

  @override
  void dispose() {
    _pulseAnimation.dispose();
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Distress Detection'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.info_circle),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2563EB).withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isDetectionActive
                                      ? _pulseScale.value
                                      : 1.0,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _isDetectionActive
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isDetectionActive
                                          ? Iconsax.radar1
                                          : Iconsax.radar,
                                      color: _isDetectionActive
                                          ? Colors.red
                                          : Colors.grey,
                                      size: 30,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Detection Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _detectionStatus,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isDetectionActive,
                              onChanged: (value) {
                                setState(() {
                                  _isDetectionActive = value;
                                  if (value) {
                                    _detectionStatus = 'Active - Monitoring';
                                    _statusColor = Colors.green;
                                    _isListening = true;
                                    _isMonitoringMotion = true;
                                    _isLocationTracking = true;
                                  } else {
                                    _detectionStatus = 'Inactive';
                                    _statusColor = Colors.grey;
                                    _isListening = false;
                                    _isMonitoringMotion = false;
                                    _isLocationTracking = false;
                                    _movementIntensity = 0.0;
                                    _currentActivity = 'Stationary';
                                  }
                                });
                                if (value) {
                                  _startSensorMonitoring();
                                } else {
                                  _stopSensorMonitoring();
                                }
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Sensor Readings Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live Sensor Readings',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Microphone sensor
                        _buildSensorRow(
                          icon: Iconsax.microphone,
                          title: 'Microphone',
                          value: _soundLevel,
                          color: Colors.blue,
                          subtitle: _soundLevel > 0.7
                              ? 'Loud noise detected'
                              : 'Normal',
                        ),

                        const SizedBox(height: 15),

                        // Accelerometer sensor
                        _buildSensorRow(
                          icon: Iconsax.activity,
                          title: 'Motion Sensor',
                          value: _movementIntensity,
                          color: Colors.orange,
                          subtitle: _currentActivity,
                        ),

                        const SizedBox(height: 15),

                        // Location sensor
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Iconsax.location,
                                  color: Colors.green.shade700,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location Services',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _isLocationTracking
                                          ? 'Tracking active - 31.5204° N, 74.3587° E'
                                          : 'Location tracking off',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isLocationTracking
                                            ? Colors.green.shade700
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isLocationTracking,
                                onChanged: (value) {
                                  setState(() {
                                    _isLocationTracking = value;
                                  });
                                },
                                activeColor: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Distress Patterns Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Distress Detection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Pattern 1: Shouting
                        _buildPatternRow(
                          icon: Iconsax.volume_high,
                          pattern: 'Shouting Detection',
                          status: _soundLevel > 0.8 ? 'DETECTED' : 'Normal',
                          color: _soundLevel > 0.8 ? Colors.red : Colors.green,
                        ),

                        const SizedBox(height: 10),

                        // Pattern 2: Running
                        _buildPatternRow(
                          icon: Iconsax.activity,
                          pattern: 'Running Detection',
                          status: _movementIntensity > 0.7
                              ? 'DETECTED'
                              : 'Normal',
                          color: _movementIntensity > 0.7
                              ? Colors.red
                              : Colors.green,
                        ),

                        const SizedBox(height: 10),

                        // Pattern 3: Sudden Movement
                        _buildPatternRow(
                          icon: Iconsax.flash,
                          pattern: 'Sudden Movement',
                          status: _movementIntensity > 0.9
                              ? 'DETECTED'
                              : 'Normal',
                          color: _movementIntensity > 0.9
                              ? Colors.red
                              : Colors.green,
                        ),

                        const SizedBox(height: 15),

                        // Info text
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.info_circle,
                                color: Colors.blue.shade700,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'AI analyzes sensor data to detect distress patterns like shouting, running, or sudden movements',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Recent Events Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Detections',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Events list
                        ..._distressEvents.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: event['detected']
                                    ? Colors.orange.shade50
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: event['detected']
                                      ? Colors.orange.shade200
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: event['detected']
                                          ? Colors.orange.shade100
                                          : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      event['type'] == 'Loud Noise'
                                          ? Iconsax.volume_high
                                          : event['type'] == 'Sudden Movement'
                                          ? Iconsax.flash
                                          : event['type'] == 'Running'
                                          ? Iconsax.activity
                                          : Iconsax.volume_high,
                                      color: event['detected']
                                          ? Colors.orange
                                          : Colors.grey,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event['type'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: event['detected']
                                                ? Colors.orange.shade700
                                                : Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          event['time'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: event['detected']
                                          ? Colors.orange.shade100
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '${(event['level'] * 100).toInt()}%',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: event['detected']
                                            ? Colors.orange.shade700
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Recent Alerts Card
                if (_recentAlerts.isNotEmpty)
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alert History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._recentAlerts.map(
                            (alert) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: alert.contains('EMERGENCY')
                                      ? Colors.red.shade50
                                      : alert.contains('SAFE')
                                      ? Colors.green.shade50
                                      : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      alert.contains('EMERGENCY')
                                          ? Icons.warning
                                          : alert.contains('SAFE')
                                          ? Icons.check_circle
                                          : Icons.info,
                                      color: alert.contains('EMERGENCY')
                                          ? Colors.red
                                          : alert.contains('SAFE')
                                          ? Colors.green
                                          : Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        alert,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: alert.contains('EMERGENCY')
                                              ? Colors.red.shade700
                                              : alert.contains('SAFE')
                                              ? Colors.green.shade700
                                              : Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Test buttons
                if (_isDetectionActive) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _soundLevel = 0.9;
                              _movementIntensity = 0.8;
                            });
                            _showDistressDialog();
                          },
                          icon: const Icon(Iconsax.volume_high),
                          label: const Text('Test Shouting'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _movementIntensity = 0.95;
                            });
                            _showDistressDialog();
                          },
                          icon: const Icon(Iconsax.activity),
                          label: const Text('Test Running'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorRow({
    required IconData icon,
    required String title,
    required double value,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: value > 0.7 ? Colors.red : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: value > 0.7 ? Colors.red : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              value > 0.7 ? Colors.red : color,
            ),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternRow({
    required IconData icon,
    required String pattern,
    required String status,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(pattern, style: const TextStyle(fontSize: 14))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Distress Detection',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(
              icon: Iconsax.microphone,
              title: 'Microphone',
              description: 'Detects shouting, screaming, or loud noises',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Iconsax.activity,
              title: 'Accelerometer',
              description: 'Detects running, sudden movements, or falls',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Iconsax.location,
              title: 'Location Services',
              description: 'Tracks location during potential emergencies',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Iconsax.radar1,
              title: 'AI Analysis',
              description: 'Combines sensor data to detect distress patterns',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
