import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:websit/landing-page/landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _exitController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _exitScaleAnimation;
  late Animation<double> _exitFadeAnimation;

  bool _isLoadingComplete = false;
  final Completer<void> _resourcesLoaded = Completer<void>();
  DocumentSnapshot? _preloadedSettings;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _exitController = AnimationController(
      duration: const Duration(milliseconds: 1500), // Slower, smoother exit
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.2, 1.0)),
    );

    // Zoom Through: Scale up significantly
    _exitScaleAnimation = Tween<double>(begin: 1.0, end: 25.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOutCubic),
    );

    // Fade Out: Opacity goes from 1.0 to 0.0
    _exitFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );

    // Start loading resources immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startLoadingProcess();
    });
  }

  Future<void> _startLoadingProcess() async {
    // Phase 1: Initial wait (Loading Screen)
    // We wait for 5 seconds AND for the basic assets (bg, logo) to be precached.
    // AND we fetch the settings for the Landing Page.

    final minWait = Future.delayed(const Duration(seconds: 2));
    final assetLoading = _precacheEssentialAssets();
    final settingsLoading = _fetchAndCacheSettings();

    await Future.wait([minWait, assetLoading, settingsLoading]);

    if (!mounted) return;

    // Transition to Phase 2 (Branded Splash)
    setState(() {
      _isLoadingComplete = true;
    });

    _startBrandedSplashPhase();
  }

  Future<void> _fetchAndCacheSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('site_data')
          .doc('settings')
          .get();

      if (!mounted) return;

      _preloadedSettings = doc;

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;

        // Precache network images from settings if available
        final List<Future<void>> precacheFutures = [];

        if (data['backgroundUrl'] is String &&
            (data['backgroundUrl'] as String).startsWith('http')) {
          precacheFutures.add(
            precacheImage(
              CachedNetworkImageProvider(data['backgroundUrl']),
              context,
            ),
          );
        }

        if (data['logoUrl'] is String &&
            (data['logoUrl'] as String).startsWith('http')) {
          precacheFutures.add(
            precacheImage(CachedNetworkImageProvider(data['logoUrl']), context),
          );
        }

        if (precacheFutures.isNotEmpty) {
          await Future.wait(precacheFutures);
        }
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    }
  }

  Future<void> _precacheEssentialAssets() async {
    try {
      await Future.wait([
        precacheImage(
          const AssetImage('assets/images/splash_bg.webp'),
          context,
        ),
        precacheImage(const AssetImage('assets/images/logo.png'), context),
      ]);
      // Signal that resources are ready
      if (!_resourcesLoaded.isCompleted) {
        _resourcesLoaded.complete();
      }
    } catch (e) {
      debugPrint('Error precaching assets: $e');
      // Even if error, we complete to not block the app
      if (!_resourcesLoaded.isCompleted) {
        _resourcesLoaded.complete();
      }
    }
  }

  void _startBrandedSplashPhase() {
    _logoController.forward();

    // Phase 2: Branded Splash
    // We wait for the animation/timer AND ensure resources are fully loaded.

    Future.delayed(const Duration(seconds: 3), () async {
      // Double check resources are loaded (should be true by now)
      await _resourcesLoaded.future;

      if (mounted) {
        // Start Exit Animation immediately
        _exitController.forward();

        // Navigate immediately so both animations play together
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                LandingPage(preloadedSettings: _preloadedSettings),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Landing Page Fades In
                  var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
                      .animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeInOut,
                        ),
                      );

                  return FadeTransition(opacity: fadeAnimation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 1500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoadingComplete ? _buildBrandedSplash() : _buildLoadingScreen(),
    );
  }

  Widget _buildLoadingScreen() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/splash_bg.webp'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Black Overlay (Same as Branded Splash)
        Container(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Welcome Text
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'مرحباً بكم في عيادة',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'NotoSansArabic',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  ' د/ سارة أحمد حامد ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'استشاري الجلدية والتجميل والليزر',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 15),

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
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.medical_services,
                          size: 60,
                          color: Colors.pink,
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 15),
                const Text(
                  'جاري التحميل...',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandedSplash() {
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/splash_bg.webp'),
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Overlay and Content
        // Apply Exit Fade Animation to the whole container
        FadeTransition(
          opacity: _exitFadeAnimation,
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo with Exit Zoom Animation
                      ScaleTransition(
                        scale: _exitScaleAnimation,
                        child: Container(
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
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.medical_services,
                                  size: 60,
                                  color: Colors.pink,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Text (will fade out with the container)
                      Column(
                        children: [
                          const Text(
                            'عيادة د/ سارة أحمد حامد',
                            style: TextStyle(
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
                          const Text(
                            'استشاري الجلدية والتجميل والليزر',
                            style: TextStyle(
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
