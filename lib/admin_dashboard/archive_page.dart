import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArchivePage extends StatefulWidget {
  const ArchivePage({super.key});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _search = _searchController.text.toLowerCase();
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
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('site_data').doc('settings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final settings = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final bgUrl = settings['backgroundUrl'];
        final hasValidBg = bgUrl is String && bgUrl.startsWith('http');

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo container
                SizedBox(
                  height: 60,
                  width: 60,
                  child: ClipOval(
                    child:
                        settings['logoUrl'] != null &&
                            settings['logoUrl'].isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: settings['logoUrl'],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Icon(
                              Icons.medical_services,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.medical_services,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Text container - wrapped in Flexible to prevent overflow
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${settings['clinicWord'] ?? 'عيادة'} ${settings['doctorName'] ?? 'د/ سارة أحمد'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'لوحة التحكم - الأرشيف',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            toolbarHeight: 80,
          ),
          body: Stack(
            children: [
              // Background image
              if (hasValidBg)
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(bgUrl),
                      fit: BoxFit.fill,
                    ),
                  ),
                )
              else
                Container(color: Colors.pink[50]),

              // Content
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'البحث في الأرشيف',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('appointments')
                          .where('date', isLessThan: todayString)
                          .orderBy('date', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final filteredDocs = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] is String
                              ? data['name'].toLowerCase()
                              : '';
                          final service = data['service'] is String
                              ? data['service'].toLowerCase()
                              : '';
                          final phone = data['phone'] is String
                              ? data['phone'].toLowerCase()
                              : '';
                          return name.contains(_search) ||
                              service.contains(_search) ||
                              phone.contains(_search);
                        }).toList();
                        return ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, i) {
                            final doc = filteredDocs[i];
                            final data = doc.data() as Map<String, dynamic>;
                            return Card(
                              color: _getStatusColor(
                                data['status'] ?? 'pending',
                              ),
                              child: ListTile(
                                title: Text(data['name'] ?? ''),
                                subtitle: Text(
                                  '${data['service'] ?? ''} - ${data['date'] ?? ''} ${data['time'] ?? ''}',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () =>
                                          _deleteAppointment(doc.id),
                                    ),
                                    Text(data['phone'] ?? ''),
                                  ],
                                ),
                                onTap: () => _showAppointmentDialog(
                                  context,
                                  doc.id,
                                  data,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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

  void _showAppointmentDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تفاصيل الحجز'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الاسم: ${data['name'] ?? ''}'),
                const SizedBox(height: 8),
                Text('الهاتف: ${data['phone'] ?? ''}'),
                const SizedBox(height: 8),
                Text('الخدمة: ${data['service'] ?? ''}'),
                const SizedBox(height: 8),
                Text('المكان: ${data['location'] ?? ''}'),
                const SizedBox(height: 8),
                Text('التاريخ: ${data['date'] ?? ''}'),
                const SizedBox(height: 8),
                Text('الوقت: ${data['time'] ?? ''}'),
                const SizedBox(height: 8),
                Text('الرسالة: ${data['message'] ?? ''}'),
                const SizedBox(height: 8),
                Text('الحالة: ${data['status'] ?? 'pending'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateStatus(docId, 'accepted');
                Navigator.of(context).pop();
              },
              child: const Text('قبول'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateStatus(docId, 'rejected');
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('رفض'),
            ),
          ],
        );
      },
    );
  }

  void _updateStatus(String docId, String status) {
    _firestore.collection('appointments').doc(docId).update({'status': status});
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
