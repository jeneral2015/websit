import 'package:cloud_firestore/cloud_firestore.dart';

class AdModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final int priority; // من 1 إلى 5
  final bool isActive;
  final String? targetUrl;
  final int views;
  final int clicks;
  final Timestamp createdAt;

  AdModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.startDate,
    required this.endDate,
    this.priority = 3,
    this.isActive = true,
    this.targetUrl,
    this.views = 0,
    this.clicks = 0,
    required this.createdAt,
  });

  factory AdModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      priority: data['priority'] ?? 3,
      isActive: data['isActive'] ?? true,
      targetUrl: data['targetUrl'],
      views: data['views'] ?? 0,
      clicks: data['clicks'] ?? 0,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'priority': priority,
      'isActive': isActive,
      'targetUrl': targetUrl,
      'views': views,
      'clicks': clicks,
      'createdAt': createdAt,
    };
  }

  bool get isExpired => DateTime.now().isAfter(endDate);
  bool get isActiveNow =>
      isActive && !isExpired && DateTime.now().isAfter(startDate);

  double get conversionRate {
    if (views == 0) return 0.0;
    return (clicks / views) * 100;
  }
}
