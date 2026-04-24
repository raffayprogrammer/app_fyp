import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax/iconsax.dart';

class CitizenHomeScreen extends StatelessWidget {
  const CitizenHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafetyGuardian'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Welcome Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.security, color: Colors.white, size: 60),
                  const SizedBox(height: 10),
                  Text(
                    'Welcome ${user?.email ?? 'User'}!',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            // Report Incident Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/report');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Report Incident', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('Report a crime or incident', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // SOS Emergency Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/sos');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.warning, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SOS Emergency', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                          SizedBox(height: 4),
                          Text('One-tap emergency alert', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Companion Mode Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/companion');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Iconsax.radar1, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Companion Mode', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                          SizedBox(height: 4),
                          Text('Trip monitoring & fall detection', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Distress Detection Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/distress');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Iconsax.radar1, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Distress Detection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
                          SizedBox(height: 4),
                          Text('AI-powered emergency detection', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.orange),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Evidence Capture Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/evidence');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.purple, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Iconsax.video, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Evidence Capture', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                          SizedBox(height: 4),
                          Text('Record audio, video & location', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.purple),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Report Prioritization Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/prioritization');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.teal, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Iconsax.graph, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Report Prioritization', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
                          SizedBox(height: 4),
                          Text('AI-powered priority analysis', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.teal),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Legal Resource Hub Button
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/legal');
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.indigo, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Iconsax.book, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Legal Resource Hub', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          SizedBox(height: 4),
                          Text('Know your rights & legal help', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.indigo),
                  ],
                ),
              ),
            ),

            // Stats Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Your Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(Icons.description, '0', 'Reports'),
                        _buildStatItem(Icons.hourglass_empty, '0', 'Pending'),
                        _buildStatItem(Icons.check_circle, '0', 'Resolved'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 30),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}