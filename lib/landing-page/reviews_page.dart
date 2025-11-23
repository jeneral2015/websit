import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'responsive_utils.dart';
import 'glowing_button.dart';
import 'widgets/auto_play_carousel.dart';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();

  // Static method to build the section for Landing Page
  static Widget buildSection(
    BuildContext context,
    Map<String, dynamic> settings,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final featuredReviewIds =
        (settings['featuredReviewIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: getResponsiveSize(context, 10, 20, 30),
        horizontal: getResponsiveSize(context, 16, 24, 32),
      ),
      color: Colors.transparent,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'تقيمات العملاء',
              style: TextStyle(
                fontSize: getResponsiveSize(context, 24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (featuredReviewIds.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'لا توجد آراء معروضة حالياً',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator(color: Colors.pink);
                }

                final reviews = snapshot.data!.docs;
                final featuredReviews = reviews.where((doc) {
                  return featuredReviewIds.contains(doc.id);
                }).toList();

                if (featuredReviews.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'لا توجد آراء معروضة حالياً',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (isMobile) {
                  // Mobile: AutoPlay Carousel
                  return AutoPlayCarousel(
                    height: 300,
                    items: featuredReviews.map((doc) {
                      final review = doc.data() as Map<String, dynamic>;
                      final url = review['url'] ?? '';
                      final title = review['title'] ?? '';
                      final description = review['description'] ?? '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildReviewCard(
                          context,
                          url,
                          title,
                          description,
                          doc.id,
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  // Desktop: Grid
                  final crossAxisCount = screenWidth > 1200
                      ? 3
                      : screenWidth > 600
                      ? 2
                      : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: getResponsiveSize(context, 12, 20, 30),
                      mainAxisSpacing: getResponsiveSize(context, 12, 20, 30),
                      childAspectRatio: getResponsiveSize(
                        context,
                        0.8,
                        1.0,
                        1.2,
                      ),
                    ),
                    itemCount: featuredReviews.length,
                    itemBuilder: (context, index) {
                      final review =
                          featuredReviews[index].data() as Map<String, dynamic>;
                      final url = review['url'] ?? '';
                      final title = review['title'] ?? '';
                      final description = review['description'] ?? '';

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 500 + (index * 200)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: _buildReviewCard(
                          context,
                          url,
                          title,
                          description,
                          featuredReviews[index].id,
                        ),
                      );
                    },
                  );
                }
              },
            ),
          const SizedBox(height: 40),
          GlowingButton(
            text: 'عرض جميع آراء العملاء',
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ReviewsPage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      var tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildReviewCard(
    BuildContext context,
    String url,
    String title,
    String description,
    String id,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/image_viewer',
        arguments: {'imageUrl': url, 'collection': 'reviews', 'documentId': id},
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.transparent,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.fill,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            if (title.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsPageState extends State<ReviewsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('reviews')
                    .where('url', isNotEqualTo: '')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'خطأ في تحميل البيانات: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد آراء عملاء بعد',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final reviews = snapshot.data!.docs;

                  final validReviews = reviews.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final url = data['url'];
                    return url != null &&
                        url.toString().isNotEmpty &&
                        url.toString().startsWith('http');
                  }).toList();

                  if (validReviews.isEmpty) {
                    return const Center(
                      child: Text(
                        'لا توجد آراء عملاء بعد',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  final screenWidth = MediaQuery.of(context).size.width;
                  final crossAxisCount = screenWidth > 1200
                      ? 3
                      : screenWidth > 600
                      ? 2
                      : 1;

                  return Padding(
                    padding: EdgeInsets.all(
                      getResponsiveSize(context, 16, 24, 32),
                    ),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: getResponsiveSize(
                          context,
                          12,
                          20,
                          30,
                        ),
                        mainAxisSpacing: getResponsiveSize(context, 12, 20, 30),
                        childAspectRatio: getResponsiveSize(
                          context,
                          0.8,
                          1.0,
                          1.2,
                        ),
                      ),
                      itemCount: validReviews.length,
                      itemBuilder: (_, i) {
                        final review =
                            validReviews[i].data() as Map<String, dynamic>;
                        final url = review['url'] ?? '';
                        final title = review['title'] ?? '';
                        final description = review['description'] ?? '';

                        return ReviewsPage._buildReviewCard(
                          context,
                          url,
                          title,
                          description,
                          validReviews[i].id,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
