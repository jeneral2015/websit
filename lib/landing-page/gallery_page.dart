import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'responsive_utils.dart';
import 'glowing_button.dart';
import 'widgets/auto_play_carousel.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();

  // Static method to build the section for Landing Page
  static Widget buildSection(
    BuildContext context,
    Map<String, dynamic> settings,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final featuredGalleryIds =
        (settings['featuredGalleryIds'] as List<dynamic>?)
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
              'معرض الأعمال',
              style: TextStyle(
                fontSize: getResponsiveSize(context, 24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 20),

          if (featuredGalleryIds.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text(
                'لا توجد صور معروضة حالياً',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('gallery')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator(color: Colors.pink);
                }

                final images = snapshot.data!.docs;
                final featuredImages = images.where((doc) {
                  return featuredGalleryIds.contains(doc.id);
                }).toList();

                if (featuredImages.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'لا توجد صور معروضة حالياً',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (isMobile) {
                  // Mobile: AutoPlay Carousel
                  return AutoPlayCarousel(
                    height: 300,
                    items: featuredImages.map((doc) {
                      final image = doc.data() as Map<String, dynamic>;
                      final url = image['url'] ?? '';
                      final title = image['title'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildImageCard(context, url, title, doc.id),
                      );
                    }).toList(),
                    enableScaleEffect: true, // تم تفعيل تأثير التكبير
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
                    itemCount: featuredImages.length,
                    itemBuilder: (context, index) {
                      final image =
                          featuredImages[index].data() as Map<String, dynamic>;
                      final url = image['url'] ?? '';
                      final title = image['title'] ?? '';
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 500 + (index * 200)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: _buildImageCard(
                          context,
                          url,
                          title,
                          featuredImages[index].id,
                        ),
                      );
                    },
                  );
                }
              },
            ),
          const SizedBox(height: 40),
          GlowingButton(
            text: 'عرض المعرض',
            onPressed: () => Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const GalleryPage(),
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

  static Widget _buildImageCard(
    BuildContext context,
    String url,
    String title,
    String id,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/image_viewer',
        arguments: {'imageUrl': url, 'collection': 'gallery', 'documentId': id},
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
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image),
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
                  child: Text(
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
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GalleryPageState extends State<GalleryPage> {
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
                        'معرض الأعمال',
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
                stream: _firestore.collection('gallery').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final images = snapshot.data!.docs;

                  final screenWidth = MediaQuery.of(context).size.width;
                  final crossAxisCount = screenWidth < 600 ? 2 : 4;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: images.length,
                      itemBuilder: (_, i) {
                        final data = images[i].data() as Map<String, dynamic>;
                        final url = data['url'] ?? '';
                        final title = data['title'] ?? '';
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/image_viewer',
                            arguments: {
                              'imageUrl': url,
                              'collection': 'gallery',
                              'documentId': images[i].id,
                            },
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.fill,
                                  width: double.infinity,
                                  height: double.infinity,
                                  placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.pink,
                                    ),
                                  ),
                                ),
                              ),
                              if (title.isNotEmpty)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.7),
                                          Colors.transparent,
                                        ],
                                      ),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
