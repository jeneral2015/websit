import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'splash_screen.dart';
import 'landing_page.dart';
import 'admin_dashboard.dart';
import 'booking_form.dart';
import 'services_page.dart';
import 'gallery_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        fontFamily: 'Tajawal',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontFamily: 'Tajawal'),
          bodyMedium: TextStyle(fontFamily: 'Tajawal'),
        ),
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
        '/landing': (context) => const LandingPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
