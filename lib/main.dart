import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:websit/firebase_options.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'splash_screen.dart';
import 'package:websit/landing-page/landing_page.dart';
import 'package:websit/landing-page/booking_form.dart';
import 'package:websit/landing-page/services_page.dart';
import 'package:websit/landing-page/gallery_page.dart';
import 'package:websit/landing-page/reviews_page.dart';
import 'package:websit/landing-page/service_details_page.dart';
import 'package:websit/landing-page/image_viewer_page.dart';
import 'package:websit/landing-page/ratings_page.dart';
import 'package:websit/auth/auth_gate.dart';
import 'package:websit/auth/login_page.dart';
import 'package:websit/admin_dashboard/archive_page.dart';

// Deferred imports for code splitting (Heavy pages only)
import 'package:websit/admin_dashboard/admin_dashboard.dart'
    deferred as admin_dashboard;

// 🔑 Top-level handler for background messages (must be outside any class)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ⚠️ Important: initialize Firebase in background isolate
  await Firebase.initializeApp();
  // You can log or handle background message here
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Initialize Firebase FIRST
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔔 Initialize FCM for background messages (MUST be before runApp) - only on mobile platforms
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    // ✅ Optional: register device token
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        debugPrint('FCM Token: $fcmToken');
      }
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  runApp(const BeautyClinicApp());
}

class BeautyClinicApp extends StatelessWidget {
  const BeautyClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    FirebaseAnalytics analytics = FirebaseAnalytics.instance;

    return MaterialApp(
      title: 'دكتورة سارة أحمد - استشاري جلدية وتجميل',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'NotoSansArabic',
        fontFamilyFallback: const ['Roboto'],
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontFamilyFallback: ['Roboto'],
          ),
          bodyMedium: TextStyle(
            fontFamily: 'NotoSansArabic',
            fontFamilyFallback: ['Roboto'],
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(162, 233, 30, 98),
          foregroundColor: Colors.white,
        ),
        cardColor: Colors.white,
        canvasColor: Colors.white,
        dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
      ),
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [Locale('ar', 'EG')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [FirebaseAnalyticsObserver(analytics: analytics)],
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const SplashScreen(), //  Start with Splash Screen
      routes: {
        '/auth_gate': (context) => const AuthGate(),
        '/login': (context) => const LoginPage(),
        '/admin': (context) => DeferredLoader(
          loadLibrary: admin_dashboard.loadLibrary,
          builder: () => admin_dashboard.AdminDashboard(),
        ),
        '/booking': (context) => const BookingForm(),
        '/services': (context) => const ServicesPage(),
        '/gallery': (context) => const GalleryPage(),
        '/reviews': (context) => const ReviewsPage(),
        '/landing': (context) => const LandingPage(),
        '/archive': (context) => const ArchivePage(),
        '/ratings': (context) => const RatingsPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/service_details') {
          final args = settings.arguments as String?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => ServiceDetailsPage(serviceId: args),
            );
          }
        } else if (settings.name == '/image_viewer') {
          final args = settings.arguments as Map<String, dynamic>?;
          if (args != null) {
            return MaterialPageRoute(
              builder: (context) => ImageViewerPage(
                imageUrl: args['imageUrl'] as String,
                collection: args['collection'] as String,
                documentId: args['documentId'] as String,
              ),
            );
          }
        }
        return null;
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// A helper widget to handle deferred loading of libraries.
class DeferredLoader extends StatelessWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;

  const DeferredLoader({
    super.key,
    required this.loadLibrary,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: loadLibrary(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return builder();
        }
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(162, 233, 30, 98),
            ),
          ),
        );
      },
    );
  }
}
