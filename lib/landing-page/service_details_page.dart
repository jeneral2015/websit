import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'glowing_button.dart';
import 'view_counter_service.dart';

class ServiceDetailsPage extends StatefulWidget {
  final String serviceId;
  final String? serviceName;

  const ServiceDetailsPage({
    super.key,
    required this.serviceId,
    this.serviceName,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ViewCounterService _viewCounter = ViewCounterService();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Increment view count when page is opened
    _viewCounter.incrementViewCount('services', widget.serviceId);
  }

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
                // Text container
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
                        'تفاصيل الخدمة',
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
              // خلفية الصورة
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

              // المحتوى
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('services')
                    .doc(widget.serviceId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.data!.exists) {
                    return const Center(
                      child: Text(
                        'الخدمة غير موجودة',
                        style: TextStyle(fontSize: 18),
                      ),
                    );
                  }

                  final service = snapshot.data!.data() as Map<String, dynamic>;
                  final title = service['title'] ?? 'خدمة';
                  final description = service['description'] ?? '';
                  final images = service['images'] as List<dynamic>? ?? [];
                  final mainImage = service['mainImage'] ?? '';

                  // Combine main image with additional images, remove duplicates
                  final allImages = [
                    mainImage,
                    ...images,
                  ].where((img) => img.toString().isNotEmpty).toSet().toList();

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image Carousel
                        if (allImages.isNotEmpty)
                          _buildImageCarousel(allImages),

                        // Service Details
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.pink,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Description
                              if (description.isNotEmpty) ...[
                                const Text(
                                  'وصف الخدمة:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.6,
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // View Counter
                              StreamBuilder<int>(
                                stream: _viewCounter.getViewCountStream(
                                  'services',
                                  widget.serviceId,
                                ),
                                builder: (context, viewSnapshot) {
                                  final views = viewSnapshot.data ?? 0;
                                  return Row(
                                    children: [
                                      const Icon(
                                        Icons.visibility,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$views مشاهدة',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 24),

                              // Booking Button
                              GlowingButton(text: 'احجز الآن', argument: title),
                            ],
                          ),
                        ),
                      ],
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

  Widget _buildImageCarousel(List<dynamic> images) {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 300,
            viewportFraction: 1.0,
            enlargeCenterPage: false,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 3),
            onPageChanged: (index, reason) {
              setState(() {
                _currentImageIndex = index;
              });
            },
          ),
          items: images.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(color: Colors.grey[200]),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl.toString(),
                    fit: BoxFit.fill,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(color: Colors.pink),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.pink[50],
                      child: const Icon(
                        Icons.medical_services,
                        size: 80,
                        color: Colors.pink,
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),

        // Image Indicator
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: images.asMap().entries.map((entry) {
              return Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentImageIndex == entry.key
                      ? Colors.pink
                      : Colors.white.withValues(alpha: 0.5),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
