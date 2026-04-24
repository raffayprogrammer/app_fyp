import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String? id;
  final String userId;
  final String userEmail;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> imageUrls;
  final DateTime timestamp;
  final String status;
  final String priority;
  
  ReportModel({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.imageUrls,
    required this.timestamp,
    required this.status,
    required this.priority,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'category': category,
      'description': description,
      'location': GeoPoint(latitude, longitude),
      'address': address,
      'images': imageUrls,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status,
      'priority': priority,
    };
  }
  
  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      latitude: (map['location'] as GeoPoint?)?.latitude ?? 0.0,
      longitude: (map['location'] as GeoPoint?)?.longitude ?? 0.0,
      address: map['address'] ?? '',
      imageUrls: List<String>.from(map['images'] ?? []),
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'medium',
    );
  }
}