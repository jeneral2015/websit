import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../notifications_manager.dart';

class AppointmentsTab extends StatefulWidget {
  final NotificationsManager notificationsManager;

  const AppointmentsTab({super.key, required this.notificationsManager});

  @override
  _AppointmentsTabState createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchText = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayString =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'البحث في المواعيد',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/archive'),
          child: const Text('عرض الأرشيف'),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('appointments')
                .orderBy('date')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading appointments: ${snapshot.error}'),
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final filteredDocs = _filterAppointments(
                snapshot.data!.docs,
                todayString,
              );

              return ListView.builder(
                itemCount: filteredDocs.length,
                itemBuilder: (context, i) {
                  final doc = filteredDocs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  return Card(
                    color: _getStatusColor(data['status'] ?? 'pending'),
                    child: ListTile(
                      title: Text(data['name'] ?? ''),
                      subtitle: Text(
                        '${data['service'] ?? ''} - ${data['date'] ?? ''} ${data['time'] ?? ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(data['phone'] ?? ''),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAppointment(doc.id),
                          ),
                        ],
                      ),
                      onTap: () => widget.notificationsManager
                          .showAppointmentDialog(context, doc.id, data),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<QueryDocumentSnapshot> _filterAppointments(
    List<QueryDocumentSnapshot> allDocs,
    String todayString,
  ) {
    final futureDocs = allDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final dateStr = data['date'] ?? '';
      return dateStr.compareTo(todayString) >= 0;
    }).toList();

    futureDocs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aDate = aData['date'] ?? '';
      final bDate = bData['date'] ?? '';
      final dateCompare = aDate.compareTo(bDate);
      if (dateCompare != 0) return dateCompare;
      final aTime = aData['time'] ?? '';
      final bTime = bData['time'] ?? '';
      return aTime.compareTo(bTime);
    });

    return futureDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = data['name'] is String ? data['name'].toLowerCase() : '';
      final service = data['service'] is String
          ? data['service'].toLowerCase()
          : '';
      final phone = data['phone'] is String ? data['phone'].toLowerCase() : '';
      return name.contains(_searchText) ||
          service.contains(_searchText) ||
          phone.contains(_searchText);
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green[100]!;
      case 'rejected':
        return Colors.red[100]!;
      case 'pending':
      default:
        return Colors.orange[100]!;
    }
  }

  void _deleteAppointment(String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل تريد حذف الحجز؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _firestore.collection('appointments').doc(docId).delete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }
}
