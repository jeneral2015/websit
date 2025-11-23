import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:websit/utils/session_manager.dart';

class RatingsPage extends StatefulWidget {
  const RatingsPage({super.key});

  @override
  State<RatingsPage> createState() => _RatingsPageState();
}

class _RatingsPageState extends State<RatingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // _likedRatings removed, using SessionManager

  @override
  Widget build(BuildContext context) {
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
            backgroundColor: const Color.fromARGB(162, 233, 30, 98),
            elevation: 0,
            toolbarHeight: 80,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: '',
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                            placeholder: (context, url) => const Icon(
                              Icons.medical_services,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.medical_services,
                            color: Colors.white,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${settings['clinicWord'] ?? 'عيادة'} ${settings['doctorName'] ?? 'د/ سارة أحمد'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'تقيمات العملاء',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_comment, color: Colors.white),
                onPressed: () => _showAddRatingDialog(context),
              ),
            ],
          ),
          body: Stack(
            children: [
              if (hasValidBg)
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(bgUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(color: Colors.pink[50]),
              _buildRatingsContent(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingsContent() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('ratings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'خطأ في تحميل التقييمات: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_outline, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'لا توجد تقييمات بعد',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showAddRatingDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('أضف أول تقييم'),
                ),
              ],
            ),
          );
        }

        final ratings = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.builder(
            itemCount: ratings.length,
            itemBuilder: (context, index) {
              final rating = ratings[index].data() as Map<String, dynamic>;
              return RatingCard(
                key: ValueKey(ratings[index].id),
                rating: rating,
                ratingId: ratings[index].id,
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showAddRatingDialog(BuildContext context) async {
    String clientName = '';
    String comment = '';
    int stars = 5;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.pink[50]!, Colors.white],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.pink,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.pink.shade300,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'أضف تقييمك',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'شاركنا تجربتك مع الخدمة',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),

                    // Stars Rating
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'كم نجمة تمنح للخدمة؟',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    stars = index + 1;
                                  });
                                },
                                child: Icon(
                                  index < stars
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 36,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$stars / 5',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Name Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'الاسم (مطلوب)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      onChanged: (value) => clientName = value,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال الاسم';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Comment Field
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'تعليقك (اختياري)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 4,
                      onChanged: (value) => comment = value,
                    ),
                    const SizedBox(height: 24),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (clientName.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('الرجاء إدخال الاسم'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (stars > 0) {
                                await _submitRating(
                                  clientName: clientName,
                                  comment: comment,
                                  stars: stars,
                                );
                                if (context.mounted) Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'إرسال التقييم',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitRating({
    required String clientName,
    required String comment,
    required int stars,
  }) async {
    try {
      await _firestore.collection('ratings').add({
        'clientName': clientName.isNotEmpty ? clientName : 'عميل',
        'comment': comment,
        'stars': stars,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser?.uid,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('شكراً لتقييمك!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل إرسال التقييم، يرجى المحاولة مرة أخرى'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class RatingCard extends StatefulWidget {
  final Map<String, dynamic> rating;
  final String ratingId;

  const RatingCard({super.key, required this.rating, required this.ratingId});

  @override
  State<RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<RatingCard> {
  @override
  Widget build(BuildContext context) {
    final clientName = widget.rating['clientName'] ?? 'عميل';
    final comment = widget.rating['comment'] ?? '';
    final stars = widget.rating['stars'] ?? 5;
    final createdAt = widget.rating['createdAt'] as Timestamp?;
    final date = createdAt != null
        ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
        : '';

    final likes = widget.rating['likes'] ?? 0;
    final isLiked = SessionManager().isLiked(widget.ratingId);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink[50]!, Colors.white],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    date,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  _buildStars(stars),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                clientName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.pink,
                ),
              ),
              const SizedBox(height: 12),
              if (comment.isNotEmpty)
                Text(
                  comment,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.right,
                ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () async {
                      if (SessionManager().isLiked(widget.ratingId)) return;

                      setState(() {
                        SessionManager().addLike(widget.ratingId);
                      });

                      final docRef = FirebaseFirestore.instance
                          .collection('ratings')
                          .doc(widget.ratingId);
                      await docRef.update({'likes': FieldValue.increment(1)});
                    },
                    child: Row(
                      children: [
                        Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: Colors.pink,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$likes',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
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
    );
  }

  Widget _buildStars(int count) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < count ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }
}
