import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/core/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);

    String inputField = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (!inputField.contains('@')) {
      inputField = '$inputField@taxitaste.com';
    }

    final result = await authService.signIn(
      inputField,
      password,
    );

    setState(() => _isLoading = false);

    if (result != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result), backgroundColor: Colors.red),
        );
      }
    } else {
      // ✅ البحث المباشر بالـ email لضمان جلب الـ role الصحيح من جدول users بالفايرستور
      String userRole = 'user';

      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: inputField)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
          if (data.containsKey('role')) {
            userRole = data['role'] ?? 'user';
          }
        }
      } catch (e) {
        debugPrint('Error fetching role by email: $e');
      }

      // حماية إضافية صريحة لإيميلك الأدمن الأساسي
      if (inputField.toLowerCase() == 'aboabad1990@gmail.com') {
        userRole = 'admin';
      }

      debugPrint('Logged in email: $inputField | Assigned Role: $userRole');

      if (mounted) {
        if (userRole == 'admin') {
          Navigator.of(context).pushReplacementNamed('/admin_dashboard');
        } else if (userRole == 'moderator') {
          Navigator.of(context).pushReplacementNamed('/moderator_dashboard');
        } else if (userRole == 'restaurant') {
          Navigator.of(context).pushReplacementNamed('/restaurant_dashboard');
        } else if (userRole == 'driver') {
          Navigator.of(context).pushReplacementNamed('/driver_dashboard');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Text(
              'أهلاً بعودتك!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'قم بتسجيل الدخول للمتابعة',
              style: TextStyle(color: AppTheme.subTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'اسم المستخدم أو البريد الإلكتروني',
                prefixIcon: Icon(Icons.person_outline),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'كلمة المرور',
                prefixIcon: Icon(Icons.lock_outline),
                suffixIcon: Icon(Icons.visibility_off_outlined),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {},
                child: const Text('نسيت كلمة المرور؟'),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}
