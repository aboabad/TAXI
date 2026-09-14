import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/core/auth_service.dart';
import 'package:taxi/features/auth/welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Header
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: const Icon(Icons.person, size: 80, color: AppTheme.primaryColor),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.displayName ?? 'مستخدم جديد',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? 'لا يوجد بريد إلكتروني',
              style: const TextStyle(color: AppTheme.subTextColor),
            ),
            const SizedBox(height: 40),
            // Settings List
            _profileMenuItem(Icons.person_outline, 'تعديل البيانات', () {}),
            _profileMenuItem(Icons.lock_outline, 'تغيير كلمة المرور', () {}),
            _profileMenuItem(Icons.notifications_none, 'إعدادات الإشعارات', () {}),
            _profileMenuItem(Icons.language, 'اللغة (العربية)', () {}),
            _profileMenuItem(Icons.help_outline, 'مركز المساعدة', () {}),
            _profileMenuItem(Icons.info_outline, 'عن التطبيق', () {}),
            const SizedBox(height: 32),
            // Logout Button
            ElevatedButton.icon(
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('تسجيل الخروج'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                elevation: 0,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _profileMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }
}
