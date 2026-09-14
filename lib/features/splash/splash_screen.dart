import 'package:flutter/material.dart';
import 'package:taxi/features/onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
const SplashScreen({super.key});

@override
State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
@override
void initState() {
super.initState();
_navigateToNext();
}

Future<void> _navigateToNext() async {
await Future.delayed(const Duration(seconds: 3));

if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => const OnboardingScreen(),
),
);
}
}

@override
Widget build(BuildContext context) {
return Scaffold(
body: Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
// Placeholder for Logo
Container(
width: 150,
height: 150,
decoration: const BoxDecoration(
color: Color(0xFF00BFA5),
shape: BoxShape.circle,
),
child: const Icon(
Icons.local_taxi,
size: 80,
color: Colors.white,
),
),
const SizedBox(height: 24),
Text(
'Taxi Taste',
style: Theme.of(context).textTheme.displayLarge?.copyWith(
color: const Color(0xFF00BFA5),
),
),
],
),
),
);
}
}