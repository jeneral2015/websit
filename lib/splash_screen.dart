import 'package:flutter/material.dart';
import 'package:websit/landing-page/landing_page.dart';
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
  bool _hasError = false;
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllResources();
    });
  }

  Future<void> _loadAllResources() async {
    try {
      debugPrint('🚀 بدء تهيئة Firebase...');

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      debugPrint('✅ Firebase تم التهيئة بنجاح');

      final settingsDoc = await FirebaseFirestore.instance
          .collection('site_data')
          .doc('settings')
          .get()
          .timeout(const Duration(seconds: 10));

      debugPrint('📄 حالة الإعدادات: ${settingsDoc.exists}');

      Map<String, dynamic> loadedSettings = {};
      if (settingsDoc.exists && settingsDoc.data() != null) {
        loadedSettings = settingsDoc.data()!;
        debugPrint('✅ تم تحميل الإعدادات من Firebase');
      }

      // Precache background
      final bgUrl = loadedSettings['backgroundUrl'];
      if (bgUrl is String && bgUrl.startsWith('http')) {
        try {
          if (mounted) {
            await precacheImage(NetworkImage(bgUrl), context);
            debugPrint('✅ تم تحميل الخلفية');
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحميل الخلفية: $e');
        }
      }

      // Precache logo
      final logoUrl = loadedSettings['logoUrl'];
      if (logoUrl is String && logoUrl.startsWith('http')) {
        try {
          if (mounted) {
            await precacheImage(NetworkImage(logoUrl), context);
            debugPrint('✅ تم تحميل اللوجو');
          }
        } catch (e) {
          debugPrint('❌ خطأ في تحميل اللوجو: $e');
        }
      }

      // Precache services — استخدام mainImage أو أول صورة من images
      try {
        final servicesSnap = await FirebaseFirestore.instance
            .collection('services')
            .get()
            .timeout(const Duration(seconds: 10));

        for (final doc in servicesSnap.docs) {
          final data = doc.data();
          String? url;

          // استخدم mainImage إذا كان موجودًا، وإلا استخدم أول صورة من images
          if (data['mainImage'] is String &&
              (data['mainImage'] as String).isNotEmpty) {
            url = data['mainImage'];
          } else if (data['images'] is List &&
              (data['images'] as List).isNotEmpty) {
            url = (data['images'] as List<dynamic>).first as String?;
          }

          if (url != null && url.startsWith('http')) {
            try {
              if (mounted) {
                await precacheImage(NetworkImage(url), context);
              }
            } catch (_) {}
          }
        }
        debugPrint('✅ تم تحميل الخدمات');
      } catch (e) {
        debugPrint('❌ خطأ في تحميل الخدمات: $e');
      }

      // Precache gallery
      try {
        final gallerySnap = await FirebaseFirestore.instance
            .collection('gallery')
            .get()
            .timeout(const Duration(seconds: 10));

        for (final doc in gallerySnap.docs) {
          final url = doc['url'] as String?;
          if (url != null && url.startsWith('http')) {
            try {
              if (mounted) {
                await precacheImage(NetworkImage(url), context);
              }
            } catch (_) {}
          }
        }
        debugPrint('✅ تم تحميل المعرض');
      } catch (e) {
        debugPrint('❌ خطأ في تحميل المعرض: $e');
      }

      // Precache reviews
      try {
        await FirebaseFirestore.instance
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .limit(5)
            .get()
            .timeout(const Duration(seconds: 10));
        debugPrint('✅ تم تحميل التقييمات');
      } catch (e) {
        debugPrint('❌ خطأ في تحميل التقييمات: $e');
      }

      if (!mounted) return;

      setState(() {
        _settings = loadedSettings;
        _isLoadingComplete = true;
        _hasError = false;
      });

      _logoController.forward();
      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;

      if (_logoController.isAnimating) {
        _logoController.stop();
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LandingPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      debugPrint('💥 خطأ عام في التحميل: $e');

      if (!mounted) return;

      setState(() {
        _hasError = true;
        // فقط في حالة الخطأ نستخدم قيمًا افتراضية للعرض
        _settings = {
          'welcomeMessage': 'مرحباً بكم في ',
          'clinicWord': 'عيادة',
          'doctorName': 'د/ سارة أحمد ',
          'specialty': 'استشاري جلدية وتجميل وليزر',
        };
      });

      _logoController.forward();
      await Future.delayed(const Duration(seconds: 5));

      if (!mounted) return;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LandingPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    if (_logoController.isAnimating) {
      _logoController.stop();
    }
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingComplete
          ? _buildBrandedSplash()
          : _buildLoadingScreen(), // تعرض البيانات فور تحميلها، بدون قيم افتراضية
    );
  }

  // لا تُستخدم إلا لاستخراج القيم — لا تُرجع قيمًا افتراضية أثناء التحميل
  dynamic _getSetting(String key) {
    return _settings[key];
  }

  Widget _buildLoadingScreen() {
    final bgUrl = _settings['backgroundUrl'];
    final hasValidBg = bgUrl is String && bgUrl.startsWith('http');
    final logoUrl = _settings['logoUrl'] as String?;

    return Container(
      decoration: hasValidBg
          ? BoxDecoration(
              image: DecorationImage(
                image: CachedNetworkImageProvider(bgUrl),
                fit: BoxFit.cover,
              ),
            )
          : const BoxDecoration(color: Colors.white),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_hasError) ...[
              const Icon(Icons.error_outline, color: Colors.orange, size: 50),
              const SizedBox(height: 15),
              Text(
                'جارٍ التحميل من البيانات المحلية',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.orange,
                  fontFamily: 'NotoSansArabic',
                ),
              ),
              const SizedBox(height: 20),
            ],
            // نعرض النصوص فقط إذا كانت متوفرة (بدون افتراضيات)
            if (_getSetting('welcomeMessage') != null ||
                _getSetting('clinicWord') != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_getSetting('welcomeMessage') != null)
                    Text(
                      _getSetting('welcomeMessage') as String,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  const SizedBox(width: 10),
                  if (_getSetting('clinicWord') != null)
                    Text(
                      _getSetting('clinicWord') as String,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.pink,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                ],
              ),
            if (_getSetting('doctorName') != null) ...[
              const SizedBox(height: 10),
              Text(
                _getSetting('doctorName') as String,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink[800],
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ],
            if (_getSetting('specialty') != null) ...[
              const SizedBox(height: 10),
              Text(
                _getSetting('specialty') as String,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.pink[700],
                  fontFamily: 'NotoSansArabic',
                ),
              ),
            ],
            const SizedBox(height: 15),
            // Logo
            if (logoUrl != null && logoUrl.startsWith('http'))
              CachedNetworkImage(
                imageUrl: logoUrl,
                width: MediaQuery.of(context).size.width * 0.3,
                height: MediaQuery.of(context).size.width * 0.3,
                fit: BoxFit.cover,
              )
            else if (_hasError)
              Image.asset(
                'assets/logo.png',
                width: MediaQuery.of(context).size.width * 0.3,
                height: MediaQuery.of(context).size.width * 0.3,
              ),
            const SizedBox(height: 15),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
            ),
            const SizedBox(height: 15),
            Text(
              'جاري التحميل...',
              style: const TextStyle(
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
    final logoUrl = _settings['logoUrl'] as String?;

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
          color: Colors.black.withValues(alpha: 0.45),
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
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: logoUrl != null && logoUrl.startsWith('http')
                            ? CachedNetworkImage(
                                imageUrl: logoUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Icon(
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
                    if (_getSetting('clinicWord') != null &&
                        _getSetting('doctorName') != null)
                      Text(
                        '${_getSetting('clinicWord')} ${_getSetting('doctorName')}',
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
                    if (_getSetting('specialty') != null)
                      Text(
                        _getSetting('specialty') as String, // ✅ تحويل آمن
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
                    if (_hasError) ...[
                      const SizedBox(height: 20),
                      Text(
                        '⚠️ استخدام البيانات المحلية',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange[200],
                          fontFamily: 'NotoSansArabic',
                        ),
                      ),
                    ],
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
