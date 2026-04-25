import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationPickerResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const LocationPickerScreen({super.key, this.initialPosition});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _picked;
  String _address = 'Loading address…';
  bool _resolving = false;

  // Default fallback: Attock, Pakistan (where COMSATS Attock is).
  static const LatLng _fallback = LatLng(33.7710, 72.3596);

  @override
  void initState() {
    super.initState();
    _picked = widget.initialPosition ?? _fallback;
    _resolveAddress(_picked!);
    _centerOnUserIfPossible();
  }

  Future<void> _centerOnUserIfPossible() async {
    if (widget.initialPosition != null) return;
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      final here = LatLng(pos.latitude, pos.longitude);
      setState(() => _picked = here);
      await _resolveAddress(here);
      _mapController.move(here, 16);
    } catch (_) {}
  }

  Future<void> _resolveAddress(LatLng pos) async {
    setState(() => _resolving = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isEmpty) {
        setState(() => _address = 'Unknown location');
      } else {
        final p = placemarks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((s) => s != null && s.isNotEmpty).toList();
        setState(() => _address = parts.join(', '));
      }
    } catch (e) {
      setState(() => _address = 'Could not resolve address');
    } finally {
      setState(() => _resolving = false);
    }
  }

  void _onTap(LatLng pos) {
    setState(() => _picked = pos);
    _resolveAddress(pos);
  }

  void _confirm() {
    if (_picked == null) return;
    Navigator.pop(
      context,
      LocationPickerResult(
        latitude: _picked!.latitude,
        longitude: _picked!.longitude,
        address: _address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Incident Location'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _picked ?? _fallback,
              initialZoom: 14,
              onTap: (tapPosition, point) => _onTap(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.safety_guardian',
                maxNativeZoom: 19,
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Card(
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _resolving
                          ? const Text(
                              'Resolving address…',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            )
                          : Text(
                              _address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.check),
          label: const Text('Use This Location'),
          onPressed: _picked == null ? null : _confirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
