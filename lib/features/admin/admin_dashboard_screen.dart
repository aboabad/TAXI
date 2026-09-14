import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/features/admin/billing_settings_screen.dart';
import 'package:taxi/features/admin/category_management_screen.dart';
import 'package:taxi/features/admin/driver_tracking_screen.dart';
import 'package:taxi/features/admin/drivers/driver_management_screen.dart';
import 'package:taxi/features/admin/restaurants/restaurant_management_screen.dart';
import 'package:taxi/features/admin/role_management_screen.dart';
import 'package:taxi/features/admin/send_notification_screen.dart';
import 'package:taxi/features/admin/users/user_management_screen.dart';
import 'package:taxi/features/profile/profile_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المشرف'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'نظرة عامة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                statCard(
                  'إجمالي العوائد',
                  '55,000 د.أ',
                  Icons.monetization_on,
                  Colors.green,
                ),
                statCard(
                  'عدد الحجوزات',
                  '1,240',
                  Icons.book_online,
                  Colors.blue,
                ),
                statCard(
                  'المستخدمين',
                  '3,500',
                  Icons.people,
                  Colors.orange,
                ),
                statCard(
                  'السائقين',
                  '150',
                  Icons.drive_eta,
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 32),

            const Text(
              'إدارة النظام',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Management Options Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                manageItem(
                  Icons.category,
                  'الفئات',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const CategoryManagementScreen(),
                      ),
                    );
                  },
                ),
                manageItem(
                  Icons.person_search,
                  'المستخدمين',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                manageItem(
                  Icons.notifications_active,
                  'الإشعارات',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const SendNotificationScreen(),
                      ),
                    );
                  },
                ),
                manageItem(
                  Icons.event_note,
                  'الحجوزات',
                      () {},
                ),
                manageItem(
                  Icons.admin_panel_settings,
                  'الأدوار',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const RoleManagementScreen(),
                      ),
                    );
                  },
                ),
                manageItem(
                  Icons.restaurant,
                  'المطاعم',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const RestaurantManagementScreen(),
                      ),
                    );
                  },
                ),
                manageItem(
                  Icons.add_business,
                  'إضافة مطعم',
                      () {
                    _showAddRestaurantDialog(context);
                  },
                ),
                manageItem(
                  Icons.drive_eta,
                  'إدارة السائقين',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const DriverManagementScreen(),
                      ),
                    );
                  },
                ),
                manageItem(
                  Icons.location_on,
                  'تتبع السواقين',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const DriverTrackingScreen(),
                      ),
                    );
                  },
                ),
                manageItem(
                  Icons.settings,
                  'الإعدادات',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const BillingSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            const Text(
              'طلبات تسجيل المطاعم الجديدة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Restaurant registration requests
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 2,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      child: Icon(Icons.restaurant),
                    ),
                    title: Text(
                      index == 0
                          ? 'مطعم برجر ستيشن'
                          : 'كافيه روقان',
                    ),
                    subtitle: const Text(
                      'انتظار مراجعة السجل التجاري',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                          ),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.cancel,
                            color: Colors.red,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRestaurantDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('إضافة مطعم جديد وإنشاء حساب'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم المطعم'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty ||
                    passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('الرجاء تعبئة كافة الحقول')),
                  );
                  return;
                }

                try {
                  // 1. إنشاء الحساب في Firebase Auth
                  UserCredential userCredential = await FirebaseAuth.instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  String uid = userCredential.user!.uid;

                  // 2. تخزين بيانات المطعم ودوره في Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .set({
                    'uid': uid,
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'role': 'restaurant',
                    'createdAt': FieldValue.serverTimestamp(),
                    'status': 'active',
                  });

                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('تم إضافة المطعم وإنشاء الحساب بنجاح')),
                  );
                } catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: $e')),
                  );
                }
              },
              child: const Text('حفظ وإنشاء'),
            ),
          ],
        );
      },
    );
  }

  Widget statCard(
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget manageItem(
      IconData icon,
      String label,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}