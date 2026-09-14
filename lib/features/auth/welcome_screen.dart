import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/features/auth/login_screen.dart';
import 'package:taxi/features/auth/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
const WelcomeScreen({super.key});

@override
Widget build(BuildContext context) {
return Scaffold(
body: SafeArea(
child: Padding(
padding: const EdgeInsets.all(24),
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Icon(
Icons.restaurant,
size: 100,
color: AppTheme.primaryColor,
),

const SizedBox(height: 30),

const Text(
'مرحباً بك',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 32,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 12),

const Text(
'اكتشف أفضل المطاعم واحجز طاولتك بسهولة',
textAlign: TextAlign.center,
style: TextStyle(
fontSize: 16,
color: AppTheme.subTextColor,
),
),

const SizedBox(height: 50),

// تسجيل الدخول
ElevatedButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const LoginScreen(),
),
);
},
child: const Text('تسجيل الدخول'),
),

const SizedBox(height: 16),

// إنشاء حساب
OutlinedButton(
onPressed: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (context) => const SignupScreen(),
),
);
},
style: OutlinedButton.styleFrom(
foregroundColor: AppTheme.primaryColor,
side: const BorderSide(
color: AppTheme.primaryColor,
),
padding: const EdgeInsets.symmetric(
vertical: 14,
),
),
child: const Text('إنشاء حساب جديد'),
),
],
),
),
),
);
}
}