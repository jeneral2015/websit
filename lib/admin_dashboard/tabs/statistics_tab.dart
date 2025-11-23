import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:websit/services/firebase_paths.dart';

class StatisticsTab extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StatisticsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('إحصائيات المواعيد'),
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('appointments').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final stats = _calculateAppointmentStats(snapshot.data!.docs);
                return Column(
                  children: [
                    _buildStatCard(
                      'إجمالي الحجوزات اليوم',
                      stats['today'].toString(),
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 10),
                    _buildStatCard(
                      'المقبولة',
                      stats['accepted'].toString(),
                      color: Colors.green,
                    ),
                    const SizedBox(height: 10),
                    _buildStatCard(
                      'المرفوضة',
                      stats['rejected'].toString(),
                      color: Colors.red,
                    ),
                    const SizedBox(height: 10),
                    _buildStatCard(
                      'في الانتظار',
                      stats['pending'].toString(),
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 10),
                    _buildStatCard(
                      'الحجوزات القادمة',
                      stats['upcoming'].toString(),
                      color: Colors.green,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            _buildSectionTitle('إحصائيات الخدمات'),
            _buildCollectionCount('services', 'عدد الخدمات'),
            const SizedBox(height: 30),
            _buildSectionTitle('إحصائيات المعرض'),
            _buildCollectionCount(FirebasePaths.gallery, 'عدد الصور'),
            const SizedBox(height: 30),
            _buildSectionTitle('إحصائيات آراء العملاء'),
            _buildCollectionCount('reviews', 'عدد الآراء'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatCard(String title, String value, {Color? color}) {
    return Card(
      color: color ?? Colors.pink[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionCount(String collection, String title) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(collection).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        final total = snapshot.data!.docs.length;
        return _buildStatCard(title, total.toString());
      },
    );
  }

  Map<String, int> _calculateAppointmentStats(
    List<QueryDocumentSnapshot> docs,
  ) {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    int accepted = 0;
    int rejected = 0;
    int pending = 0;
    int totalToday = 0;
    int upcomingAccepted = 0;

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? '';
      final dateStr = data['date'] ?? '';

      if (status == 'accepted') {
        accepted++;
        try {
          final date = DateTime.parse(dateStr);
          if (date.isAfter(today)) upcomingAccepted++;
        } catch (_) {}
      } else if (status == 'rejected') {
        rejected++;
      } else {
        pending++;
      }

      if (dateStr == todayString) totalToday++;
    }

    return {
      'today': totalToday,
      'accepted': accepted,
      'rejected': rejected,
      'pending': pending,
      'upcoming': upcomingAccepted,
    };
  }
}
