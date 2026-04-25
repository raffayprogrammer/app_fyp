import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_button.dart';
import '../services/sos_service.dart';
import '../services/call_handler_service.dart';
import 'manage_contacts_screen.dart';

class EmergencySOSScreen extends StatefulWidget {
  const EmergencySOSScreen({super.key});

  @override
  State<EmergencySOSScreen> createState() => _EmergencySOSScreenState();
}

class _EmergencySOSScreenState extends State<EmergencySOSScreen>
    with SingleTickerProviderStateMixin {
  // Animation for SOS button
  late AnimationController _pulseAnimation;
  late Animation<double> _pulseScale;

  // State variables - ONLY ONE sosService
  final SosService _sosService = SosService();
  final CallHandlerService _callHandlerService = CallHandlerService();

  bool _isEmergencyActive = false;
  bool _isLocationSharing = false;
  bool _isCalling = false;
  // Contacts for UI display
  List<Map<String, dynamic>> _trustedContacts = [
    {
      'name': 'Mother',
      'phone': '+92 300 1234567',
      'status': 'waiting',
      'called': false,
    },
    {
      'name': 'Father',
      'phone': '+92 321 7654321',
      'status': 'waiting',
      'called': false,
    },
    {
      'name': 'Brother',
      'phone': '+92 345 9876543',
      'status': 'waiting',
      'called': false,
    },
  ];
  String _emergencyStatus = 'Ready';
  Color _statusColor = Colors.green;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation for SOS button
    _pulseAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseAnimation, curve: Curves.easeInOut),
    );

    _refreshContactsFromService();
  }

  // Pull the real saved trusted contacts (from SharedPreferences via
  // SosService) so the UI mirrors what the SOS cascade will actually call.
  Future<void> _refreshContactsFromService() async {
    await _sosService.loadContacts();
    if (!mounted) return;
    setState(() {
      _trustedContacts = _sosService.trustedContacts
          .map((c) => {
                'name': c['name'] ?? '',
                'phone': c['phone'] ?? '',
                'status': 'waiting',
                'called': false,
              })
          .toList();
    });
  }

  @override
  void dispose() {
    _pulseAnimation.dispose();
    _callHandlerService.stopListening();
    super.dispose();
  }

  // Activate emergency mode
  void _activateEmergency() async {
    setState(() {
      _isEmergencyActive = true;
      _isLocationSharing = true;
      _isCalling = true;
      _emergencyStatus = 'EMERGENCY ACTIVE';
      _statusColor = Colors.red;
    });

    // Start auto-reject handler
    _callHandlerService.startListening(true);

    // Start REAL SOS (calls and SMS) - Trusted contacts first, Police last
    await _sosService.startSos();

    // After all contacts tried, show response options
    _showResponseOptions();
  }

  // Show response options after emergency
  void _showResponseOptions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Are you safe?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Let your contacts know your status',
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
                      _updateEmergencyStatus('safe');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                            size: 40,
                          ),
                          const SizedBox(height: 10),
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
                      _updateEmergencyStatus('help');
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                            size: 40,
                          ),
                          const SizedBox(height: 10),
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
          ],
        ),
      ),
    );
  }

  // Update emergency status based on user response
  void _updateEmergencyStatus(String status) {
    setState(() {
      if (status == 'safe') {
        _emergencyStatus = 'You are safe';
        _statusColor = Colors.green;
        _isEmergencyActive = false;
        _isLocationSharing = false;
        _callHandlerService.setEmergencyMode(false);
        _sosService.stopSos();
      } else {
        _emergencyStatus = 'HELP REQUIRED';
        _statusColor = Colors.red;
        _callHandlerService.setEmergencyMode(true);
      }
    });

    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == 'safe'
              ? 'Your contacts have been notified you are safe'
              : 'Emergency services alerted. Help is on the way!',
        ),
        backgroundColor: status == 'safe' ? Colors.green : Colors.red,
      ),
    );
  }

  // Toggle location sharing
  void _toggleLocationSharing() {
    setState(() {
      _isLocationSharing = !_isLocationSharing;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLocationSharing
              ? 'Live location sharing activated'
              : 'Location sharing stopped',
        ),
        backgroundColor: _isLocationSharing ? Colors.green : Colors.orange,
      ),
    );
  }

  // Add new trusted contact

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Emergency'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
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
                  Colors.red.shade700,
                  Colors.red.shade400,
                  Colors.orange.shade300,
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
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white.withOpacity(0.95),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _statusColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _isEmergencyActive
                                    ? Icons.warning
                                    : Icons.check_circle,
                                color: _statusColor,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    _emergencyStatus,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isLocationSharing)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.green,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'LIVE',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // SOS Button
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isEmergencyActive ? 1.0 : _pulseScale.value,
                        child: GestureDetector(
                          onTap: _isEmergencyActive ? null : _activateEmergency,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [
                                  Colors.red,
                                  Colors.redAccent,
                                  Colors.orange,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.5),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.white,
                                  size: 60,
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'SOS',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_isEmergencyActive)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Emergency Info Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Emergency Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildActionRow(
                          icon: Icons.call,
                          color: Colors.red,
                          title: 'Police Emergency (15)',
                          subtitle: 'Calling immediately',
                          isActive: _isEmergencyActive,
                        ),
                        const Divider(height: 20),
                        _buildActionRow(
                          icon: Icons.message,
                          color: Colors.blue,
                          title: 'SMS Alerts',
                          subtitle: 'Sent to trusted contacts',
                          isActive: _isEmergencyActive,
                        ),
                        const Divider(height: 20),
                        _buildActionRow(
                          icon: Icons.location_on,
                          color: Colors.green,
                          title: 'Live Location',
                          subtitle: _isLocationSharing
                              ? 'Sharing'
                              : 'Not sharing',
                          isActive: _isLocationSharing,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Trusted Contacts Section
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Trusted Contacts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ManageContactsScreen(),
                                  ),
                                );
                                await _refreshContactsFromService();
                              },
                              icon: const Icon(Iconsax.setting_2, size: 16),
                              label: const Text('Manage'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ..._trustedContacts.map(
                          (contact) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _buildContactRow(contact),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Auto-call Handling Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Auto-Call Features',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildFeatureRow(
                          icon: Icons.block,
                          title: 'Incoming calls auto-rejected',
                          subtitle: 'During emergency mode',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureRow(
                          icon: Iconsax.message,
                          title: 'Automated responses',
                          subtitle: 'I\'m Safe / Help Needed',
                        ),
                        const SizedBox(height: 10),
                        _buildFeatureRow(
                          icon: Icons.currency_rupee,
                          title: 'Works without balance',
                          subtitle: 'Emergency numbers only',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Location Toggle Button
                if (_isEmergencyActive)
                  CustomButton(
                    text: _isLocationSharing
                        ? 'Stop Sharing Location'
                        : 'Share Live Location',
                    onPressed: _toggleLocationSharing,
                    color: _isLocationSharing ? Colors.orange : Colors.green,
                  ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // Loading overlay during emergency
          if (_isCalling)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                        ),
                        SizedBox(height: 15),
                        Text('Activating Emergency...'),
                        Text(
                          'Calling Police (15)',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.green : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(Map<String, dynamic> contact) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: contact['called']
                ? contact['status'] == 'no_answer'
                      ? Colors.orange.shade100
                      : Colors.green.shade100
                : Colors.blue.shade100,
            child: Icon(
              contact['called']
                  ? contact['status'] == 'no_answer'
                        ? Icons.phone_missed
                        : Icons.check
                  : Icons.person,
              color: contact['called']
                  ? contact['status'] == 'no_answer'
                        ? Colors.orange
                        : Colors.green
                  : Colors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  contact['phone'],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (contact['called'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: contact['status'] == 'no_answer'
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                contact['status'] == 'no_answer' ? 'No Answer' : 'Called',
                style: TextStyle(
                  fontSize: 10,
                  color: contact['status'] == 'no_answer'
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF2563EB)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
