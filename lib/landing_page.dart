import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services_page.dart';
import 'gallery_page.dart';
import 'booking_form.dart';
import 'admin_dashboard.dart';
import 'glowing_button.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _weeklySchedule = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settingsDoc = await _firestore
          .collection('site_data')
          .doc('settings')
          .get();
      if (settingsDoc.exists) {
        final data = settingsDoc.data() as Map<String, dynamic>;
        setState(() {
          _settings = data;
          _weeklySchedule =
              (data['weeklySchedule'] as List<dynamic>?)
                  ?.cast<Map<String, dynamic>>()
                  .where((e) => e['enabled'] == true)
                  .toList() ??
              [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bgUrl = _settings['backgroundUrl'];
    final hasValidBg = bgUrl is String && bgUrl.startsWith('http');

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(
          162,
          233,
          30,
          98,
        ), // خلفية بينك للهيدر
        elevation: 0,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_settings['logoUrl'] != null &&
                    _settings['logoUrl'].isNotEmpty)
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _settings['logoUrl'],
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Icon(
                        Icons.medical_services,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  'عيادة ${_settings['doctorName'] ?? 'د/ سارة أحمد'}',
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Text(
              _settings['specialty'] ?? 'استشاري جلدية وتجميل وليزر',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        toolbarHeight: 80,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            ),
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
          ),
        ],
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
          SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroSection(),
                _buildAboutSection(),
                _buildServicesSection(),
                _buildScheduleSection(),
                _buildGallerySection(),
                _buildContactSection(),
              ],
            ),
          ),

          // الأيقونة العائمة
          Positioned(
            bottom: 20,
            left: 20,
            child: FloatingActionMenu(
              settings: _settings,
              onNavigate: _navigateWithAnimation,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 1000),
            opacity: 1,
            child: Text(
              'مرحباً بكم في عيادة',
              style: TextStyle(
                fontSize: _getResponsiveSize(24, 32, 40),
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 104, 6, 104),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 1200),
            opacity: 1,
            child: Text(
              _settings['doctorName'] ?? 'د/ سارة أحمد حامد',
              style: TextStyle(
                fontSize: _getResponsiveSize(20, 28, 36),
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 104, 6, 104),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 1400),
            opacity: 1,
            child: Text(
              _settings['specialty'] ?? 'استشاري جلدية وتجميل وليزر',
              style: TextStyle(
                fontSize: _getResponsiveSize(16, 20, 24),
                color: const Color.fromARGB(255, 104, 6, 104),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 1600),
            opacity: 1,
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              alignment: WrapAlignment.center,
              children: [
                GlowingButton(text: 'حجز موعد', argument: 'حجز موعد'),
                GlowingButton(
                  text: 'خدماتنا',
                  onPressed: () => _navigateWithAnimation(const ServicesPage()),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildAboutSection() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: _getResponsiveSize(20, 30, 40),
        horizontal: _getResponsiveSize(16, 24, 32),
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
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'عن الطبيبة',
              style: TextStyle(
                fontSize: _getResponsiveSize(24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 30),
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            constraints: BoxConstraints(
              maxWidth: _getResponsiveSize(400, 800, 1200),
            ),
            padding: EdgeInsets.all(_getResponsiveSize(16, 24, 32)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Text(
              _settings['aboutText'] ??
                  'طبيبة متخصصة في أمراض الجلدية والتناسلية والتجميل الطبي والليزر، بخبرة تزيد عن 15 عامًا في تشخيص وعالج مشاكل الجلد وتنفيذ الإجراءات التجميلية غير الجراحية.',
              style: TextStyle(
                fontSize: _getResponsiveSize(14, 18, 20),
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

  Widget _buildServicesSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 3
        : screenWidth > 600
        ? 2
        : 1;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: _getResponsiveSize(20, 30, 40),
        horizontal: _getResponsiveSize(16, 24, 32),
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
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'خدماتنا',
              style: TextStyle(
                fontSize: _getResponsiveSize(24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 40),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('services').limit(3).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator(color: Colors.pink);
              }

              final services = snapshot.data!.docs;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: _getResponsiveSize(12, 20, 30),
                  mainAxisSpacing: _getResponsiveSize(12, 20, 30),
                  childAspectRatio: _getResponsiveSize(0.8, 1.0, 1.2),
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service =
                      services[index].data() as Map<String, dynamic>;
                  return _buildServiceCard(service);
                },
              );
            },
          ),
          const SizedBox(height: 40),
          GlowingButton(
            text: 'عرض جميع الخدمات',
            onPressed: () => _navigateWithAnimation(const ServicesPage()),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // الكونتينر الداخلي للصورة
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.transparent,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child:
                  service['imageUrl'] != null && service['imageUrl'].isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: service['imageUrl'],
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: double.infinity,
                      placeholder: (_, __) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                    )
                  : Container(
                      color: Colors.pink.withOpacity(0.3),
                      child: const Icon(
                        Icons.medical_services,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          // تدرج خفيف للنص
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              ),
            ),
          ),

          // المحتوى في الأسفل
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // اسم الخدمة على اليمين
                  Expanded(
                    child: Text(
                      service['title'] ?? 'خدمة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: _getResponsiveSize(14, 16, 18),
                      ),
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // زر الحجز على الشمال
                  GlowingButton(
                    text: 'احجز الآن',
                    argument: service['title'] ?? 'خدمة',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    if (_weeklySchedule.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: _getResponsiveSize(20, 30, 40),
        horizontal: _getResponsiveSize(16, 24, 32),
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
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'مواعيد العمل',
              style: TextStyle(
                fontSize: _getResponsiveSize(24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 40),
          isLargeScreen
              ? Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: _weeklySchedule
                      .map((day) => _buildScheduleItem(day))
                      .toList(),
                )
              : Column(
                  children: _weeklySchedule
                      .map((day) => _buildScheduleItem(day))
                      .toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> day) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: MediaQuery.of(context).size.width > 600 ? 400 : double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.pink,
                      size: _getResponsiveSize(16, 20, 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      day['day'] ?? '',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: _getResponsiveSize(14, 16, 18),
                      ),
                    ),
                    if (day['location']?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      Text(
                        '-',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveSize(14, 16, 18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        day['location'],
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: _getResponsiveSize(14, 16, 18),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${day['startTime']} - ${day['endTime']}',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: _getResponsiveSize(12, 14, 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GlowingButton(
            text: 'احجز الان',
            onPressed: () => _navigateWithAnimation(const BookingForm()),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: _getResponsiveSize(20, 30, 40),
        horizontal: _getResponsiveSize(16, 24, 32),
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
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'معرض الأعمال',
              style: TextStyle(
                fontSize: _getResponsiveSize(24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 40),
          StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('gallery').limit(3).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const CircularProgressIndicator(color: Colors.pink);
              }

              final images = snapshot.data!.docs;
              final screenWidth = MediaQuery.of(context).size.width;
              final crossAxisCount = screenWidth > 600 ? 3 : 1;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: _getResponsiveSize(8, 16, 24),
                  mainAxisSpacing: _getResponsiveSize(8, 16, 24),
                  childAspectRatio: 1.0,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index].data() as Map<String, dynamic>;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: image['url'] ?? '',
                        fit: BoxFit.fill,
                        placeholder: (_, __) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.broken_image),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 40),
          GlowingButton(
            text: 'عرض المعرض',
            onPressed: () => _navigateWithAnimation(const GalleryPage()),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    final phone = _settings['phone'] ?? '+201234567890';
    final location = _settings['location'] ?? 'https://maps.google.com';
    final facebookUrl = _settings['facebookUrl'] ?? '';
    final instagramUrl = _settings['instagramUrl'] ?? '';
    final tiktokUrl = _settings['tiktokUrl'] ?? '';
    final whatsappUrl = _settings['whatsappUrl'] ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: _getResponsiveSize(20, 30, 40),
        horizontal: 0,
      ),
      color: const Color.fromARGB(162, 233, 30, 98),
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
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'تواصل معنا',
              style: TextStyle(
                fontSize: _getResponsiveSize(24, 32, 40),
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: [
              _buildContactIcon(
                icon: FontAwesomeIcons.phone,
                label: 'اتصال',
                color: Colors.blue,
                onPressed: () => launchUrl(Uri.parse('tel:$phone')),
              ),
              _buildContactIcon(
                icon: FontAwesomeIcons.whatsapp,
                label: 'واتساب',
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
              _buildContactIcon(
                icon: FontAwesomeIcons.locationDot,
                label: 'الموقع',
                color: Colors.red,
                onPressed: () => launchUrl(Uri.parse(location)),
              ),
              if (facebookUrl.isNotEmpty)
                _buildContactIcon(
                  icon: FontAwesomeIcons.facebook,
                  label: 'فيسبوك',
                  color: Colors.blue,
                  onPressed: () => launchUrl(Uri.parse(facebookUrl)),
                ),
              if (instagramUrl.isNotEmpty)
                _buildContactIcon(
                  icon: FontAwesomeIcons.instagram,
                  label: 'إنستغرام',
                  color: Colors.pink,
                  onPressed: () => launchUrl(Uri.parse(instagramUrl)),
                ),
              if (tiktokUrl.isNotEmpty)
                _buildContactIcon(
                  icon: FontAwesomeIcons.tiktok,
                  label: 'تيك توك',
                  color: Colors.black,
                  onPressed: () => launchUrl(Uri.parse(tiktokUrl)),
                ),
              _buildContactIcon(
                icon: Icons.calendar_today,
                label: 'حجز موعد',
                color: Colors.deepPurple,
                onPressed: () => _navigateWithAnimation(const BookingForm()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactIcon({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPressed,
            child: CircleAvatar(
              radius: _getResponsiveSize(20, 25, 30),
              backgroundColor: color,
              child: Icon(
                icon,
                color: Colors.white,
                size: _getResponsiveSize(16, 20, 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: _getResponsiveSize(12, 14, 16),
              fontWeight: FontWeight.w500,
              color: Colors.pink,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: _getResponsiveSize(16, 20, 24)),
        label: Text(
          label,
          style: TextStyle(fontSize: _getResponsiveSize(12, 14, 16)),
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.pink,
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveSize(16, 24, 32),
            vertical: _getResponsiveSize(8, 12, 16),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  double _getResponsiveSize(double small, double medium, double large) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return small;
    if (screenWidth < 1200) return medium;
    return large;
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      _isOpen ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // الأزرار الفرعية
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
                            ),
                            if (widget.settings['facebookUrl']?.isNotEmpty ==
                                true)
                              _buildFabItem(
                                FontAwesomeIcons.facebook,
                                () => launchUrl(
                                  Uri.parse(widget.settings['facebookUrl']),
                                ),
                                Colors.blue,
                              ),
                            if (widget.settings['instagramUrl']?.isNotEmpty ==
                                true)
                              _buildFabItem(
                                FontAwesomeIcons.instagram,
                                () => launchUrl(
                                  Uri.parse(widget.settings['instagramUrl']),
                                ),
                                Colors.pink,
                              ),
                            if (widget.settings['tiktokUrl']?.isNotEmpty ==
                                true)
                              _buildFabItem(
                                FontAwesomeIcons.tiktok,
                                () => launchUrl(
                                  Uri.parse(widget.settings['tiktokUrl']),
                                ),
                                Colors.black,
                              ),
                            _buildFabItem(
                              FontAwesomeIcons.calendar,
                              () => widget.onNavigate(const BookingForm()),
                              Colors.deepPurple,
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          },
        ),

        // الزر الرئيسي
        FloatingActionButton(
          backgroundColor: Colors.pink,
          onPressed: _toggle,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _controller,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildFabItem(
    IconData icon,
    VoidCallback onPressed,
    Color backgroundColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: FloatingActionButton(
        mini: true,
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
