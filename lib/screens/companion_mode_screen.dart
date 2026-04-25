import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';
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
  GoogleMapController? _mapController;

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
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 15),
      );
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
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_destination!, 14));
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

    // Live position updates -> drive the marker on the map.
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
      _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation!));
      _checkRouteDeviation();
    });

    // Push location to Firestore every 15 seconds.
    _firestorePushTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pushUpdate(),
    );
    // Also push immediately so a viewer sees the session right away.
    await _writeSessionStart();
    _pushUpdate();
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

  // Route-deviation check: compare last 4 distance-to-destination readings.
  // Each consecutive reading must grow by > 10 m (above GPS jitter) to flag.
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
              // Auto-triggered: try every trusted contact in order before 15.
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

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_currentLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('me'),
        position: _currentLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You'),
      ));
    }
    if (_destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Destination', snippet: _destinationAddress),
      ));
    }
    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (_currentLocation == null || _destination == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_currentLocation!, _destination!],
        color: const Color(0xFF2563EB),
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
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
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentLocation ?? const LatLng(33.7710, 72.3596),
                zoom: 14,
              ),
              onMapCreated: (c) => _mapController = c,
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
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
