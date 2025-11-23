import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:websit/firebase_options.dart';
import 'splash_screen.dart';
import 'package:websit/landing-page/landing_page.dart';
import 'package:websit/admin_dashboard/admin_dashboard.dart';
import 'package:websit/landing-page/booking_form.dart';
import 'package:websit/landing-page/services_page.dart';
import 'package:websit/landing-page/gallery_page.dart';
import 'package:websit/landing-page/reviews_page.dart';
import 'package:websit/landing-page/service_details_page.dart';
import 'package:websit/landing-page/image_viewer_page.dart';
import 'package:websit/admin_dashboard/archive_page.dart';
import 'package:websit/landing-page/ratings_page.dart';
// ← مهم جدًا

// 🔑 Top-level handler for background messages (must be outside any class)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // ⚠️ Important: initialize Firebase in background isolate
  await Firebase.initializeApp();
  // You can log or handle background message here
  debugPrint("Handling a background message: ${message.messageId}");
  // Optionally: show local notification here for background-only handling
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Initialize Firebase FIRST
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔔 Initialize FCM for background messages (MUST be before runApp) - only on mobile platforms
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseMessaging.instance.setAutoInitEnabled(true);

    // ✅ Optional: register device token (useful for targeted notifications later)
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        // Save to Firestore if you want (e.g., in 'devices' collection)
        // Example:
        // FirebaseFirestore.instance.collection('devices').doc(fcmToken).set({
        //   'token': fcmToken,
        //   'platform': defaultTargetPlatform.toString(),
        //   'lastSeen': FieldValue.serverTimestamp(),
        // });
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
    return MaterialApp(
      title: 'دكتورة سارة أحمد - استشاري جلدية وتجميل',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        fontFamily: 'NotoSansArabic',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'NotoSansArabic'),
          bodyMedium: TextStyle(fontFamily: 'NotoSansArabic'),
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
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const SplashScreen(),
      routes: {
        '/admin': (context) => const AdminDashboard(),
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
