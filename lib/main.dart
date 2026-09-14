import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'package:taxi/core/app_theme.dart';
import 'package:taxi/core/auth_service.dart';
import 'package:taxi/features/admin/admin_dashboard_screen.dart';
import 'package:taxi/features/auth/login_screen.dart';
import 'package:taxi/features/driver/driver_home_screen.dart';
import 'package:taxi/features/home/home_screen.dart';
import 'package:taxi/features/restaurant/restaurant_dashboard_screen.dart';
import 'package:taxi/features/splash/splash_screen.dart';
import 'package:taxi/services/notification_service.dart';
import 'package:taxi/services/order_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode
        ? const AndroidPlayIntegrityProvider()
        : const AndroidDebugProvider(),
    providerApple: kReleaseMode
        ? const AppleAppAttestProvider()
        : const AppleDebugProvider(),
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
        '/': (_) => const AuthWrapper(),
        '/home': (_) => const HomeScreen(),
        '/login': (_) => const LoginScreen(),
        '/admin_dashboard': (_) => const AdminDashboardScreen(),
        '/restaurant_dashboard': (_) => const RestaurantDashboardScreen(),
        '/driver_dashboard': (_) => const DriverHomeScreen(),
        '/driver_home_screen': (_) => const DriverHomeScreen(),
        '/moderator_dashboard': (_) => const HomeScreen(),
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

        final firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const SplashScreen();
        }

        final authService = Provider.of<AuthService>(context, listen: false);
        return FutureBuilder<String>(
          future: authService.getUserRole(firebaseUser.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            switch (roleSnapshot.data ?? 'user') {
              case 'admin':
                return const AdminDashboardScreen();
              case 'driver':
                return const DriverHomeScreen();
              case 'restaurant':
                return const RestaurantDashboardScreen();
              case 'moderator':
              case 'user':
              default:
                return const HomeScreen();
            }
          },
        );
      },
    );
  }
}
