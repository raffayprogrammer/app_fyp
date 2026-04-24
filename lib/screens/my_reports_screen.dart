import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          var reports = snapshot.data!.docs;
          
          if (reports.isEmpty) {
            return const Center(child: Text('No reports submitted yet'));
          }
          
          return ListView.builder(
            itemCount: reports.length,
            itemBuilder: (context, index) {
              var report = reports[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(report['category']),
                subtitle: Text('Status: ${report['status']}'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () {
                  // Show report details
                },
              );
            },
          );
        },
      ),
    );
  }
}