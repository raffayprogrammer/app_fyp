import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_button.dart';
import 'package:iconsax/iconsax.dart';

class CompanionModeScreen extends StatefulWidget {
  const CompanionModeScreen({super.key});

  @override
  State<CompanionModeScreen> createState() => _CompanionModeScreenState();
}

class _CompanionModeScreenState extends State<CompanionModeScreen> {
  // State variables
  bool _isMonitoring = false;
  bool _isSharingLocation = false;
  bool _isDeviationAlert = true;
  bool _isFallDetection = true;
  String _selectedContact = 'Mother';
  String _tripStatus = 'Ready to start';
  Color _statusColor = Colors.grey;
  
  // Trip details
  String _startLocation = 'Home';
  String _destination = 'Office';
  double _progress = 0.0;
  
  // Trusted contacts list
  List<Map<String, dynamic>> _trustedContacts = [
    {'name': 'Mother', 'phone': '+92 300 1234567', 'selected': true},
    {'name': 'Father', 'phone': '+92 321 7654321', 'selected': false},
    {'name': 'Brother', 'phone': '+92 345 9876543', 'selected': false},
    {'name': 'Sister', 'phone': '+92 312 4567890', 'selected': false},
  ];

  // Route deviations (for demo)
  List<Map<String, dynamic>> _routeDeviations = [
    {'time': '2 min ago', 'location': 'Main Boulevard', 'status': 'normal'},
    {'time': '5 min ago', 'location': 'Market Area', 'status': 'deviation'},
    {'time': '10 min ago', 'location': 'Hospital Road', 'status': 'normal'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companion Mode'),
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
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isMonitoring
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isMonitoring
                                    ? Iconsax.radar1  // Changed from radar
                                    : Iconsax.location_slash,
                                color: _isMonitoring ? Colors.green : Colors.orange,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trip Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _tripStatus,
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
                              value: _isMonitoring,
                              onChanged: (value) {
                                setState(() {
                                  _isMonitoring = value;
                                  if (value) {
                                    _tripStatus = 'Monitoring Active';
                                    _statusColor = Colors.green;
                                  } else {
                                    _tripStatus = 'Monitoring Stopped';
                                    _statusColor = Colors.red;
                                  }
                                });
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

                // Trip Details Card
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
                          'Current Trip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        
                        // Start location
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.location,
                                color: Colors.green,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _startLocation,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        
                        // Dotted line
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Column(
                            children: List.generate(
                              3,
                              (index) => Container(
                                width: 2,
                                height: 8,
                                margin: const EdgeInsets.only(left: 0.5),
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                        
                        // Destination
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Iconsax.location_tick,
                                color: Colors.red,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _destination,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Progress bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Trip Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                Text(
                                  '${(_progress * 100).toInt()}%',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2563EB),
                              ),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        
                        // Simulate progress buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isMonitoring
                                    ? () {
                                        setState(() {
                                          if (_progress < 1.0) {
                                            _progress += 0.25;
                                          }
                                        });
                                      }
                                    : null,
                                child: const Text('+25%'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isMonitoring
                                    ? () {
                                        setState(() {
                                          _progress = 0.0;
                                        });
                                      }
                                    : null,
                                child: const Text('Reset'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // AI Monitoring Features Card
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Iconsax.cpu,
                                color: Colors.purple,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'AI Monitoring',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        
                        // Route deviation toggle
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.map,  // Changed from route
                                color: Colors.orange.shade700,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Route Deviation Detection',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Alerts if you go off route',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isDeviationAlert,
                                onChanged: (value) {
                                  setState(() {
                                    _isDeviationAlert = value;
                                  });
                                },
                                activeColor: Colors.orange,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Fall detection toggle
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.warning_2,  // Changed from ruler
                                color: Colors.red.shade700,
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fall & Sudden Stop Detection',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Detects falls or sudden movements',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isFallDetection,
                                onChanged: (value) {
                                  setState(() {
                                    _isFallDetection = value;
                                  });
                                },
                                activeColor: Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Trusted Contacts Card
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sharing with',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Manage'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        
                        // Contacts list
                        ..._trustedContacts.map((contact) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: contact['selected']
                                    ? Colors.green.shade100
                                    : Colors.grey.shade200,
                                child: Icon(
                                  Icons.person,
                                  color: contact['selected']
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      contact['name'],
                                      style: TextStyle(
                                        fontWeight: contact['selected']
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    Text(
                                      contact['phone'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (contact['selected'])
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    'SHARING',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Recent Alerts Card
                if (_isMonitoring) ...[
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
                            'Recent Alerts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          
                          // Alert list
                          ..._routeDeviations.map((deviation) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: deviation['status'] == 'deviation'
                                    ? Colors.orange.shade50
                                    : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    deviation['status'] == 'deviation'
                                        ? Icons.warning
                                        : Icons.check_circle,
                                    color: deviation['status'] == 'deviation'
                                        ? Colors.orange
                                        : Colors.green,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deviation['location'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          deviation['time'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (deviation['status'] == 'deviation')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'DEVIATION',
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Control Buttons
                if (!_isMonitoring)
                  CustomButton(
                    text: 'Start Trip Monitoring',
                    onPressed: () {
                      setState(() {
                        _isMonitoring = true;
                        _tripStatus = 'Monitoring Active';
                        _statusColor = Colors.green;
                      });
                    },
                    color: Colors.green,
                  )
                else
                  CustomButton(
                    text: 'Stop Monitoring',
                    onPressed: () {
                      setState(() {
                        _isMonitoring = false;
                        _tripStatus = 'Monitoring Stopped';
                        _statusColor = Colors.red;
                        _progress = 0.0;
                      });
                    },
                    color: Colors.red,
                  ),

                const SizedBox(height: 20),
              ],
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Companion Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(
              icon: Iconsax.radar1,  // Changed from radar
              title: 'Real-time Tracking',
              description: 'Share your trip live with trusted contacts',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Iconsax.map,  // Changed from route
              title: 'Route Deviation',
              description: 'Get alerts if you go off your planned route',
            ),
            const Divider(),
            _buildInfoRow(
              icon: Iconsax.warning_2,  // Changed from ruler
              title: 'Fall Detection',
              description: 'Automatic alerts for sudden stops or falls',
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}