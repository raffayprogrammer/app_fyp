import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker_screen.dart';
import '../services/sos_service.dart';

/// Companion Mode — citizen shares live location while traveling.
/// Pushes current GPS to Firestore every ~15 seconds while active so trusted
/// contacts (or police) can follow along until the trip ends.
class CompanionModeScreen extends StatefulWidget {
  const CompanionModeScreen({super.key});

  @override
  State<CompanionModeScreen> createState() => _CompanionModeScreenState();
}

class _CompanionModeScreenState extends State<CompanionModeScreen> {
  final MapController _mapController = MapController();

  LatLng? _currentLocation;
  LatLng? _destination;
  String _destinationAddress = '';

  StreamSubscription<Position>? _positionSub;
  Timer? _firestorePushTimer;
  DateTime? _startedAt;
  Position? _lastPosition;
  int _updatesPushed = 0;

  bool _active = false;

  // Route-deviation detection: keep the last few distance-to-destination
  // readings. If each consecutive reading grows by more than 10m, the user
  // is moving AWAY from the destination — flag it once per session.
  final List<double> _recentDistances = [];
  bool _deviationFlagged = false;

  @override
  void initState() {
    super.initState();
    _seedCurrentLocation();
  }

  Future<void> _seedCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
        _lastPosition = pos;
      });
      _mapController.move(_currentLocation!, 15);
    } catch (_) {}
  }

  Future<void> _pickDestination() async {
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialPosition: _currentLocation),
      ),
    );
    if (result != null) {
      setState(() {
        _destination = LatLng(result.latitude, result.longitude);
        _destinationAddress = result.address;
      });
      _mapController.move(_destination!, 14);
    }
  }

  Future<void> _start() async {
    if (_destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a destination first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final permission = await Geolocator.requestPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _active = true;
      _startedAt = DateTime.now();
      _updatesPushed = 0;
      _recentDistances.clear();
      _deviationFlagged = false;
    });

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _lastPosition = pos;
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentLocation!, _mapController.camera.zoom);
      _checkRouteDeviation();
    });

    _firestorePushTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pushUpdate(),
    );
    await _writeSessionStart();
    _pushUpdate();
  }

  void _checkRouteDeviation() {
    if (_lastPosition == null || _destination == null || _deviationFlagged) {
      return;
    }
    final dist = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    _recentDistances.add(dist);
    if (_recentDistances.length > 4) _recentDistances.removeAt(0);

    if (_recentDistances.length < 4) return;
    for (int i = 1; i < _recentDistances.length; i++) {
      if (_recentDistances[i] - _recentDistances[i - 1] < 10) return;
    }

    _deviationFlagged = true;
    _writeDeviationFlag();
    _showDeviationDialog();
  }

  Future<void> _writeDeviationFlag() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('companion_sessions')
        .doc(user.uid)
        .set({
      'deviationDetected': true,
      'deviationAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _showDeviationDialog() {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Possible Route Deviation'),
          ],
        ),
        content: const Text(
          'You appear to be moving away from your destination. Are you safe?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("I'm OK"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              SosService().startSos(sequential: true);
            },
            icon: const Icon(Icons.warning, size: 18),
            label: const Text('Help'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pushUpdate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _lastPosition == null) return;
    await FirebaseFirestore.instance
        .collection('companion_sessions')
        .doc(user.uid)
        .set({
      'currentLocation': {
        'lat': _lastPosition!.latitude,
        'lng': _lastPosition!.longitude,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
    if (!mounted) return;
    setState(() => _updatesPushed += 1);
  }

  Future<void> _writeSessionStart() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _destination == null) return;
    await FirebaseFirestore.instance
        .collection('companion_sessions')
        .doc(user.uid)
        .set({
      'userId': user.uid,
      'userEmail': user.email,
      'destination': {
        'lat': _destination!.latitude,
        'lng': _destination!.longitude,
        'address': _destinationAddress,
      },
      'startedAt': FieldValue.serverTimestamp(),
      'active': true,
    });
  }

  Future<void> _stop() async {
    _positionSub?.cancel();
    _positionSub = null;
    _firestorePushTimer?.cancel();
    _firestorePushTimer = null;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('companion_sessions')
          .doc(user.uid)
          .set({
        'active': false,
        'endedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    if (!mounted) return;
    setState(() => _active = false);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _firestorePushTimer?.cancel();
    super.dispose();
  }

  String _distanceToDestText() {
    if (_lastPosition == null || _destination == null) return '—';
    final meters = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _elapsedText() {
    if (_startedAt == null) return '—';
    final d = DateTime.now().difference(_startedAt!);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (_currentLocation != null) {
      markers.add(Marker(
        point: _currentLocation!,
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: Colors.blue, size: 36),
      ));
    }
    if (_destination != null) {
      markers.add(Marker(
        point: _destination!,
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ));
    }
    return markers;
  }

  List<Polyline> _buildPolylines() {
    if (_currentLocation == null || _destination == null) return [];
    return [
      Polyline(
        points: [_currentLocation!, _destination!],
        color: const Color(0xFF2563EB),
        strokeWidth: 4,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companion Mode'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? const LatLng(33.7710, 72.3596),
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.safety_guardian',
                  maxNativeZoom: 19,
                ),
                PolylineLayer(polylines: _buildPolylines()),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Iconsax.location_tick, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _destination == null
                            ? 'No destination picked'
                            : _destinationAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: _active ? null : _pickDestination,
                      child: Text(_destination == null ? 'Pick' : 'Change'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_active) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _stat('Distance', _distanceToDestText()),
                      _stat('Elapsed', _elapsedText()),
                      _stat('Updates', _updatesPushed.toString()),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(_active ? Iconsax.stop_circle : Iconsax.play),
                    label: Text(_active ? 'Stop Tracking' : 'Start Tracking'),
                    onPressed: _active ? _stop : _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _active ? Colors.red : const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
