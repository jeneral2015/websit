import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingsManagementTab extends StatefulWidget {
  const RatingsManagementTab({super.key});

  @override
  State<RatingsManagementTab> createState() => _RatingsManagementTabState();
}

class _RatingsManagementTabState extends State<RatingsManagementTab> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('حدث خطأ في تحميل البيانات'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ratings = snapshot.data!.docs;

        if (ratings.isEmpty) {
          return const Center(child: Text('لا توجد تقييمات حالياً'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ratings.length,
          itemBuilder: (context, index) {
            final doc = ratings[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildRatingCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildRatingCard(String docId, Map<String, dynamic> data) {
    final clientName = data['clientName'] ?? 'عميل';
    final comment = data['comment'] ?? '';
    final stars = data['stars'] ?? 5;
    final likes = data['likes'] ?? 0;
    final createdAt = data['createdAt'] as Timestamp?;
    final date = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  clientName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$stars',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (comment.isNotEmpty) ...[
              Text(comment, style: const TextStyle(color: Colors.black87)),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.pink, size: 16),
                const SizedBox(width: 4),
                Text('$likes إعجاب'),
                const Spacer(),
                Text(
                  date,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditDialog(docId, data),
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  label: const Text(
                    'تعديل',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _confirmDelete(docId),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('حذف', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(String docId, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['clientName']);
    final commentController = TextEditingController(text: data['comment']);
    final likesController = TextEditingController(
      text: (data['likes'] ?? 0).toString(),
    );
    int stars = data['stars'] ?? 5;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('تعديل التقييم'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم العميل'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: commentController,
                    decoration: const InputDecoration(labelText: 'التعليق'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: likesController,
                    decoration: const InputDecoration(
                      labelText: 'عدد الإعجابات',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('التقييم (نجوم)'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            stars = index + 1;
                          });
                        },
                        icon: Icon(
                          index < stars ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _firestore.collection('ratings').doc(docId).update({
                      'clientName': nameController.text,
                      'comment': commentController.text,
                      'likes': int.tryParse(likesController.text) ?? 0,
                      'stars': stars,
                    });
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('حدث خطأ أثناء التحديث')),
                      );
                    }
                  }
                },
                child: const Text('حفظ'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا التقييم؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('ratings').doc(docId).delete();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الحذف')));
        }
      }
    }
  }
}
