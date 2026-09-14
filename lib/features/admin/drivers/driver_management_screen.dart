import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DriverManagementScreen extends StatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  State<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends State<DriverManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddDriverDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة سائق جديد'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم السائق'),
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال الاسم' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال البريد الإلكتروني' : null,
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                  keyboardType: TextInputType.phone,
                  validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'كلمة السر'),
                  obscureText: true,
                  validator: (val) => val != null && val.length < 6 ? 'كلمة السر يجب أن تكون 6 أحرف على الأقل' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // إنشاء حساب جديد للسائق في Firebase Auth
                  final UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  );

                  // حفظ بيانات السائق في Firestore
                  await _firestore.collection('users').doc(userCred.user!.uid).set({
                    'uid': userCred.user!.uid,
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'role': 'driver',
                    'isAvailable': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  // التحقق المباشر من dialogContext بدلاً من mounted العامة
                  if (!dialogContext.mounted) return;

                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('تم إنشاء حساب السائق وتسجيله بنجاح')),
                  );
                } catch (e) {
                  if (kDebugMode) {
                    debugPrint('خطأ أثناء إضافة السائق: $e');
                  }

                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السائقين'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDriverDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').where('role', isEqualTo: 'driver').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final drivers = snapshot.data?.docs ?? [];

          if (drivers.isEmpty) {
            return const Center(child: Text('لا يوجد سائقون مسجلون حالياً'));
          }

          return ListView.builder(
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final driver = drivers[index].data() as Map<String, dynamic>;
              final String name = driver['name'] ?? 'بدون اسم';
              final String phone = driver['phone'] ?? 'بدون رقم';
              final bool isAvailable = driver['isAvailable'] ?? false;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(name.isNotEmpty ? name[0] : 'D'),
                ),
                title: Text(name),
                subtitle: Text(phone),
                trailing: Chip(
                  label: Text(isAvailable ? 'متاح' : 'غير متاح'),
                  backgroundColor: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                  labelStyle: TextStyle(
                    color: isAvailable ? Colors.green.shade900 : Colors.red.shade900,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}