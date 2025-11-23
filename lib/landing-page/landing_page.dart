import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services_page.dart';
import 'gallery_page.dart';
import 'reviews_page.dart';
import 'ratings_page.dart';
import 'booking_form.dart';
import 'glowing_button.dart';
import 'responsive_utils.dart';
import 'package:websit/utils/session_manager.dart';
import 'package:websit/landing-page/widgets/auto_play_carousel.dart';
import 'package:websit/auth/auth_gate.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // _likedRatings removed, using SessionManager

  // أضف متغير للتحكم في تأثير Hover في حالة الشاشات الكبيرة
  final Map<int, bool> _isHovered = {};

  void _startHoverAnimation(int index) {
    setState(() {
      _isHovered[index] = true;
    });
  }

  void _stopHoverAnimation(int index) {
    setState(() {
      _isHovered[index] = false;
    });
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
        final weeklySchedule =
            (settings['weeklySchedule'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>()
                .where((e) => e['enabled'] == true)
                .toList() ??
            [];

        final bgUrl = settings['backgroundUrl'];
        final hasValidBg = bgUrl is String && bgUrl.startsWith('http');

        return Scaffold(
          extendBodyBehindAppBar: false,
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
                // Text container
                SizedBox(
                  height: 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${settings['clinicWord'] ?? 'عيادة'} ${settings['doctorName'] ?? 'د/ سارة أحمد'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        settings['specialty'] ?? 'استشاري جلدية وتجميل وليزر',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            toolbarHeight: 80,
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                ),
                icon: Icon(
                  Icons.admin_panel_settings,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          body: Stack(
            children: [
              // خلفية الصورة
              // خلفية الصورة
              if (hasValidBg)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: CachedNetworkImageProvider(bgUrl),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                )
              else
                Positioned.fill(child: Container(color: Colors.pink[50])),

              // المحتوى
              SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSection(settings),
                    ServicesPage.buildSection(context, settings),
                    _buildAboutSection(settings),
                    BookingForm.buildScheduleSection(context, weeklySchedule),
                    GalleryPage.buildSection(context, settings),
                    ReviewsPage.buildSection(context, settings),
                    _buildRatingsSection(settings),
                    _buildContactSection(settings),
                  ],
                ),
              ),

              // الأيقونة العائمة
              Positioned(
                bottom: 20,
                left: 20,
                child: FloatingActionMenu(
                  settings: settings,
                  onNavigate: _navigateWithAnimation,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(Map<String, dynamic> settings) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final heroHeightFactor = screenWidth < 600
        ? 0.40 // Mobile: smaller to show services carousel
        : screenWidth < 1200
        ? 0.55 // Tablet
        : 0.6; // Desktop

    return Container(
      height: screenHeight * heroHeightFactor,
      padding: EdgeInsets.symmetric(
        horizontal: getResponsiveSize(context, 16, 24, 32),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: getResponsiveSize(context, 8, 12, 16)),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1000),
              opacity: 1,
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    settings['welcomeMessage'] ?? 'مرحباً بكم في عيادة',
                    style: TextStyle(
                      fontSize: getResponsiveSize(context, 20, 28, 36),
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 190, 16, 74),
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    settings['clinicWord'] ?? 'عيادة',
                    style: TextStyle(
                      fontSize: getResponsiveSize(context, 20, 28, 36),
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 190, 16, 74),
                      shadows: [
                        Shadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: getResponsiveSize(context, 8, 12, 16)),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1200),
              opacity: 1,
              child: Text(
                settings['doctorName'] ?? 'د/ سارة أحمد حامد',
                style: TextStyle(
                  fontSize: getResponsiveSize(context, 18, 26, 34),
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 190, 16, 74),
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: getResponsiveSize(context, 6, 10, 12)),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1400),
              opacity: 1,
              child: Text(
                settings['specialty'] ?? 'استشاري جلدية وتجميل وليزر',
                style: TextStyle(
                  fontSize: getResponsiveSize(context, 14, 18, 22),
                  color: const Color.fromARGB(255, 190, 16, 74),
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: getResponsiveSize(context, 6, 10, 12)),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1500),
              opacity: 1,
              child: Text(
                settings['experience'] ??
                    'بخبرة اكثر من 15 عام فى احدث التقنيات',
                style: TextStyle(
                  fontSize: getResponsiveSize(context, 14, 18, 22),
                  color: const Color.fromARGB(255, 190, 16, 74),
                  shadows: [
                    Shadow(
                      color: Colors.white.withValues(alpha: 0.7),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: getResponsiveSize(context, 8, 12, 16)),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 1600),
              opacity: 1,
              child: _buildNavigationIcons(),
            ),
            SizedBox(height: getResponsiveSize(context, 8, 12, 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationIcons() {
    final icons = [
      {
        'icon': FontAwesomeIcons.handHoldingMedical,
        'label': 'خدماتنا',
        'page': const ServicesPage(),
        'color': Colors.blue,
      },
      {
        'icon': FontAwesomeIcons.images,
        'label': 'المعرض',
        'page': const GalleryPage(),
        'color': Colors.purple,
      },
      {
        'icon': FontAwesomeIcons.comments,
        'label': 'آراء العملاء',
        'page': const ReviewsPage(),
        'color': Colors.orange,
      },
      {
        'icon': Icons.star,
        'label': 'التقييمات',
        'page': const RatingsPage(),
        'color': Colors.amber,
      },
      {
        'icon': FontAwesomeIcons.calendarCheck,
        'label': 'حجز موعد',
        'page': const BookingForm(),
        'color': const Color.fromARGB(255, 190, 16, 74),
      },
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: icons.map((item) {
        return _AnimatedIconBtn(
          icon: item['icon'] as IconData,
          label: item['label'] as String,
          color: item['color'] as Color,
          onTap: () => _navigateWithAnimation(item['page'] as Widget),
        );
      }).toList(),
    );
  }

  void _navigateWithAnimation(Widget page) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    );
  }

  Widget _buildAboutSection(Map<String, dynamic> settings) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: getResponsiveSize(context, 5, 12, 17),
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
              'عن الطبيبة',
              style: TextStyle(
                fontSize: getResponsiveSize(context, 24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            constraints: BoxConstraints(
              maxWidth: getResponsiveSize(context, 400, 800, 1200),
            ),
            padding: EdgeInsets.all(getResponsiveSize(context, 16, 24, 32)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              settings['aboutText'] ??
                  'طبيبة متخصصة في أمراض الجلدية والتناسلية والتجميل الطبي والليزر، بخبرة تزيد عن 15 عامًا في تشخيص وعالج مشاكل الجلد وتنفيذ الإجراءات التجميلية غير الجراحية.',
              style: TextStyle(
                fontSize: getResponsiveSize(context, 14, 18, 20),
                height: 1.6,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(Map<String, dynamic> settings) {
    final phone = settings['phone'] ?? '+201234567890';
    final location = settings['location'] ?? 'https://maps.google.com';
    final facebookUrl = settings['facebookUrl'] ?? '';
    final instagramUrl = settings['instagramUrl'] ?? '';
    final tiktokUrl = settings['tiktokUrl'] ?? '';
    final whatsappUrl = settings['whatsappUrl'] ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: getResponsiveSize(context, 30, 40, 50),
        horizontal: 20,
      ),
      color: const Color.fromARGB(162, 233, 30, 98),
      child: Column(
        children: [
          // Header-like Info (Logo + Name)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                      : const Icon(Icons.medical_services, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '${settings['clinicWord'] ?? 'عيادة'} ${settings['doctorName'] ?? 'د/ سارة أحمد'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    settings['specialty'] ?? 'استشاري جلدية وتجميل وليزر',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Simplified Social Icons
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildSimpleContactIcon(
                icon: FontAwesomeIcons.phone,
                color: Colors.blue,
                onPressed: () => launchUrl(Uri.parse('tel:$phone')),
              ),
              _buildSimpleContactIcon(
                icon: FontAwesomeIcons.whatsapp,
                color: Colors.green,
                onPressed: () => launchUrl(
                  Uri.parse(
                    whatsappUrl.isNotEmpty
                        ? (whatsappUrl.startsWith('http')
                              ? whatsappUrl
                              : 'https://wa.me/$whatsappUrl')
                        : 'https://wa.me/$phone',
                  ),
                ),
              ),
              _buildSimpleContactIcon(
                icon: FontAwesomeIcons.locationDot,
                color: Colors.red,
                onPressed: () => launchUrl(Uri.parse(location)),
              ),
              if (facebookUrl.isNotEmpty)
                _buildSimpleContactIcon(
                  icon: FontAwesomeIcons.facebook,
                  color: Colors.blue,
                  onPressed: () => launchUrl(Uri.parse(facebookUrl)),
                ),
              if (instagramUrl.isNotEmpty)
                _buildSimpleContactIcon(
                  icon: FontAwesomeIcons.instagram,
                  color: Colors.pink,
                  onPressed: () => launchUrl(Uri.parse(instagramUrl)),
                ),
              if (tiktokUrl.isNotEmpty)
                _buildSimpleContactIcon(
                  icon: FontAwesomeIcons.tiktok,
                  color: Colors.black,
                  onPressed: () => launchUrl(Uri.parse(tiktokUrl)),
                ),
              _buildSimpleContactIcon(
                icon: Icons.star,
                color: Colors.amber,
                onPressed: () => _navigateWithAnimation(const RatingsPage()),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Copyright
          const Text(
            'جميع الحقوق محفوظة © 2025',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleContactIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 24),
        tooltip: '',
      ),
    );
  }

  Widget _buildRatingsSection(Map<String, dynamic> settings) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final featuredRatingIds =
        (settings['featuredRatingIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: getResponsiveSize(context, 20, 30, 40),
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
              'تقييمات الزوار',
              style: TextStyle(
                fontSize: getResponsiveSize(context, 24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 40),

          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('ratings')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator(color: Colors.pink);
              }

              final allRatings = snapshot.data!.docs;

              if (featuredRatingIds.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'لا توجد تقييمات مختارة للعرض حالياً',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              final displayRatings = allRatings.where((doc) {
                return featuredRatingIds.contains(doc.id);
              }).toList();

              if (displayRatings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    'لا توجد تقييمات مختارة للعرض حالياً',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              if (isMobile) {
                return AutoPlayCarousel(
                  height: 240,
                  items: displayRatings.map((doc) {
                    final rating = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: RatingPreviewCard(
                        rating: rating,
                        ratingId: doc.id,
                      ),
                    );
                  }).toList(),
                  enableScaleEffect: true, // تم تفعيل تأثير التكبير
                );
              } else {
                // Desktop Grid with hover effect
                final crossAxisCount = screenWidth > 1200 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: getResponsiveSize(context, 12, 20, 30),
                    mainAxisSpacing: getResponsiveSize(context, 12, 20, 30),
                    childAspectRatio: getResponsiveSize(context, 1.5, 1.8, 2.0),
                  ),
                  itemCount: displayRatings.length,
                  itemBuilder: (context, index) {
                    final rating =
                        displayRatings[index].data() as Map<String, dynamic>;
                    return MouseRegion(
                      onEnter: (_) => _startHoverAnimation(index),
                      onExit: (_) => _stopHoverAnimation(index),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 500 + (index * 200)),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              transform: Matrix4.diagonal3Values(
                                _isHovered[index] == true ? 1.05 : 1.0,
                                _isHovered[index] == true ? 1.05 : 1.0,
                                _isHovered[index] == true ? 1.05 : 1.0,
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: RatingPreviewCard(
                          rating: rating,
                          ratingId: displayRatings[index].id,
                        ),
                      ),
                    );
                  },
                );
              }
            },
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlowingButton(
                text: 'عرض جميع التقييمات',
                onPressed: () => _navigateWithAnimation(const RatingsPage()),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _showAddRatingDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.pink,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 4),
                    Text('أضف تقييم'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
        builder: (dialogContext, setState) {
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
                            onPressed: () => Navigator.pop(dialogContext),
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
                                ScaffoldMessenger.of(
                                  dialogContext,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text('الرجاء إدخال الاسم'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (stars > 0) {
                                try {
                                  await _firestore.collection('ratings').add({
                                    'clientName': clientName.isNotEmpty
                                        ? clientName
                                        : 'عميل',
                                    'comment': comment,
                                    'stars': stars,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text('شكراً لتقييمك!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (dialogContext.mounted) {
                                    ScaffoldMessenger.of(
                                      dialogContext,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'فشل إرسال التقييم، يرجى المحاولة مرة أخرى',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
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
}

// الأيقونة العائمة مع قائمة منسدلة
class FloatingActionMenu extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Function(Widget) onNavigate;

  const FloatingActionMenu({
    super.key,
    required this.settings,
    required this.onNavigate,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
        _startAutoCloseTimer();
      } else {
        _controller.reverse();
        _autoCloseTimer?.cancel();
      }
    });
  }

  void _startAutoCloseTimer() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isOpen) {
        _toggle();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // Sub-buttons
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _controller.value,
              child: Opacity(
                opacity: _controller.value,
                child: _isOpen
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 80, right: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildFabItem(
                              FontAwesomeIcons.phone,
                              () => launchUrl(
                                Uri.parse(
                                  'tel:${widget.settings['phone'] ?? '+201234567890'}',
                                ),
                              ),
                              Colors.blue,
                              'phone',
                            ),
                            _buildFabItem(
                              FontAwesomeIcons.whatsapp,
                              () => launchUrl(
                                Uri.parse(
                                  widget.settings['whatsappUrl']?.isNotEmpty ==
                                          true
                                      ? (widget.settings['whatsappUrl']
                                                .startsWith('http')
                                            ? widget.settings['whatsappUrl']
                                            : 'https://wa.me/${widget.settings['whatsappUrl']}')
                                      : 'https://wa.me/${widget.settings['phone'] ?? '+201234567890'}',
                                ),
                              ),
                              Colors.green,
                              'whatsapp',
                            ),
                            _buildFabItem(
                              FontAwesomeIcons.locationDot,
                              () => launchUrl(
                                Uri.parse(
                                  widget.settings['location'] ??
                                      'https://maps.google.com',
                                ),
                              ),
                              Colors.red,
                              'location',
                            ),
                            if (widget.settings['facebookUrl']?.isNotEmpty ==
                                true)
                              _buildFabItem(
                                FontAwesomeIcons.facebook,
                                () => launchUrl(
                                  Uri.parse(widget.settings['facebookUrl']),
                                ),
                                Colors.blue,
                                'facebook',
                              ),
                            if (widget.settings['instagramUrl']?.isNotEmpty ==
                                true)
                              _buildFabItem(
                                FontAwesomeIcons.instagram,
                                () => launchUrl(
                                  Uri.parse(widget.settings['instagramUrl']),
                                ),
                                Colors.pink,
                                'instagram',
                              ),
                            if (widget.settings['tiktokUrl']?.isNotEmpty ==
                                true)
                              _buildFabItem(
                                FontAwesomeIcons.tiktok,
                                () => launchUrl(
                                  Uri.parse(widget.settings['tiktokUrl']),
                                ),
                                Colors.black,
                                'tiktok',
                              ),
                            _buildFabItem(
                              FontAwesomeIcons.calendar,
                              () => widget.onNavigate(const BookingForm()),
                              Colors.deepPurple,
                              'calendar',
                            ),
                            _buildFabItem(
                              Icons.star,
                              () => widget.onNavigate(const RatingsPage()),
                              Colors.amber,
                              'ratings',
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),

        // Main Button
        FloatingActionButton(
          backgroundColor: Colors.pink,
          onPressed: _toggle,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 3.14, // Rotate 180 degrees
                child: Icon(
                  _isOpen ? Icons.close : FontAwesomeIcons.headset,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFabItem(
    IconData icon,
    VoidCallback onPressed,
    Color backgroundColor,
    String heroTag,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FloatingActionButton(
        heroTag: heroTag,
        mini: true,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      ),
    );
  }
}

class RatingPreviewCard extends StatefulWidget {
  final Map<String, dynamic> rating;
  final String ratingId;

  const RatingPreviewCard({
    super.key,
    required this.rating,
    required this.ratingId,
  });

  @override
  State<RatingPreviewCard> createState() => _RatingPreviewCardState();
}

class _RatingPreviewCardState extends State<RatingPreviewCard> {
  @override
  Widget build(BuildContext context) {
    final clientName = widget.rating['clientName'] ?? 'عميل';
    final comment = widget.rating['comment'] ?? '';
    final stars = widget.rating['stars'] ?? 5;
    final likes = widget.rating['likes'] ?? 0;
    final isLiked = SessionManager().isLiked(widget.ratingId);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
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
                  color: Colors.pink,
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < stars ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (comment.isNotEmpty)
            Text(
              comment.length > 100
                  ? '${comment.substring(0, 100)}...'
                  : comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          const SizedBox(height: 8),
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
                      size: 16,
                      color: Colors.pink,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$likes',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedIconBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedIconBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedIconBtn> createState() => _AnimatedIconBtnState();
}

class _AnimatedIconBtnState extends State<_AnimatedIconBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(
                        alpha: _isHovered ? 0.6 : 0.3,
                      ),
                      blurRadius: _isHovered ? 15 : 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
                child: Icon(widget.icon, color: widget.color, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _isHovered ? widget.color : Colors.grey[700],
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}
