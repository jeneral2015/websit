import 'package:flutter/material.dart';
import 'landing_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoadingComplete = false;
  Map<String, dynamic> _settings = {};

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.2, 1.0)),
    );

    // بدء التحميل بعد الإطار الأول لضمان توفر الـ context
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllResources();
    });
  }

  Future<void> _loadAllResources() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Load settings
      final settingsDoc = await FirebaseFirestore.instance
          .collection('site_data')
          .doc('settings')
          .get();

      if (settingsDoc.exists) {
        _settings = settingsDoc.data() as Map<String, dynamic>;
      }

      // Precache background
      final bgUrl = _settings['backgroundUrl'];
      if (bgUrl is String && bgUrl.startsWith('http')) {
        try {
          await precacheImage(NetworkImage(bgUrl), context);
        } catch (_) {}
      }

      // Precache logo
      final logoUrl = _settings['logoUrl'] ?? '';
      if (logoUrl is String && logoUrl.startsWith('http')) {
        try {
          await precacheImage(NetworkImage(logoUrl), context);
        } catch (_) {}
      }

      // Precache services
      final servicesSnap = await FirebaseFirestore.instance
          .collection('services')
          .get();
      for (final doc in servicesSnap.docs) {
        final url = doc['imageUrl'] as String?;
        if (url != null && url.startsWith('http')) {
          try {
            await precacheImage(NetworkImage(url), context);
          } catch (_) {}
        }
      }

      // Precache gallery
      final gallerySnap = await FirebaseFirestore.instance
          .collection('gallery')
          .get();
      for (final doc in gallerySnap.docs) {
        final url = doc['url'] as String?;
        if (url != null && url.startsWith('http')) {
          try {
            await precacheImage(NetworkImage(url), context);
          } catch (_) {}
        }
      }

      // Precache reviews (load first few reviews)
      await FirebaseFirestore.instance
          .collection('reviews')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      // كل حاجة خلصت!
      if (!mounted) return;

      setState(() {
        _isLoadingComplete = true;
      });

      // نبدأ الـ animation
      _logoController.forward();

      // نبقي في صفحة الـ branded لمدة 1.2 ثانية
      await Future.delayed(const Duration(milliseconds: 1200));

      if (!mounted) return;

      // نروح للصفحة التالية بنعومة
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LandingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      // حتى لو حصل خطأ، نكمل
      if (!mounted) return;
      _logoController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
    }
  }

  @override
  void dispose() {
    _logoController.stop();
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingComplete
          ? _buildBrandedSplash()
          : _buildWhiteLoadingScreen(),
    );
  }

  Widget _buildWhiteLoadingScreen() {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
            SizedBox(height: 20),
            Text(
              'جاري التحميل...',
              style: TextStyle(
                fontSize: 18,
                color: Colors.pink,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandedSplash() {
    final bgUrl = _settings['backgroundUrl'];
    final hasValidBg = bgUrl is String && bgUrl.startsWith('http');
    final logoUrl = _settings['logoUrl'] ?? '';

    return Stack(
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

        Container(
          color: Colors.black.withOpacity(0.45),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: logoUrl.isNotEmpty && logoUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: logoUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Icon(
                                  Icons.medical_services,
                                  size: 60,
                                  color: Colors.pink,
                                ),
                              )
                            : const Icon(
                                Icons.medical_services,
                                size: 60,
                                color: Colors.pink,
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'عيادة ${_settings['doctorName'] ?? 'د/ سارة أحمد'}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansArabic',
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 3,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _settings['specialty'] ?? 'استشاري جلدية وتجميل وليزر',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'NotoSansArabic',
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 2,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
