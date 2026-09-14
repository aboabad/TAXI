import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:taxi/core/app_theme.dart';
import 'package:taxi/core/auth_service.dart';
import 'package:taxi/features/driver/driver_home_screen.dart';
import 'package:taxi/features/home/home_screen.dart';
import 'package:taxi/features/splash/splash_screen.dart';
import 'package:taxi/features/auth/login_screen.dart';
import 'package:taxi/services/notification_service.dart';
import 'package:taxi/services/order_service.dart';

// ✅ ربط شاشة الأدمن وشاشة المطعم
import 'package:taxi/features/admin/admin_dashboard_screen.dart';
import 'package:taxi/features/restaurant/restaurant_dashboard_screen.dart'; // تأكد إن مسار الشاشة عندك هيك أو عدله حسب مكانها

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  final notificationService = NotificationService();
  await notificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => OrderService()),
        Provider.value(value: notificationService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Taxi Taste',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar')],
      locale: const Locale('ar'),

      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin_dashboard': (context) => const AdminDashboardScreen(),
        '/restaurant_dashboard': (context) => const RestaurantDashboardScreen(),
        '/driver_dashboard': (context) => const DriverHomeScreen(),
        '/driver_home_screen': (context) => const DriverHomeScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const SplashScreen();
        }

        return FutureBuilder<String?>(
          future: _getUserRole(authSnapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final userRole = roleSnapshot.data ?? 'user';

            // ✅ التوجيه الصحيح شاملاً دور المطعم
            switch (userRole) {
              case 'admin':
                return const AdminDashboardScreen();
              case 'driver':
                return const DriverHomeScreen();
              case 'restaurant':
                return const RestaurantDashboardScreen(); // 👈 الشاشة المضافة للمطعم
              case 'moderator':
                return const HomeScreen();
              default:
                return const HomeScreen();
            }
          },
        );
      },
    );
  }

  Future<String?> _getUserRole(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }
}