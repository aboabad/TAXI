import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

class DriverManagementScreen extends StatelessWidget {
  const DriverManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة السائقين'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestore
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final drivers = snapshot.data?.docs ?? [];
          if (drivers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا يوجد سائقون مسجلون حالياً.\nيمكن تحويل أي حساب إلى سائق من شاشة إدارة الحسابات.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            itemBuilder: (context, index) {
              final doc = drivers[index];
              final driver = doc.data();
              final name = driver['name']?.toString() ?? 'بدون اسم';
              final phone = driver['phone']?.toString() ?? 'بدون رقم';
              final email = driver['email']?.toString() ?? '';
              final isAvailable = driver['isAvailable'] == true;
              final active = driver['active'] != false;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name.characters.first : 'D',
                      style: const TextStyle(color: AppTheme.primaryColor),
                    ),
                  ),
                  title: Text(name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phone),
                      if (email.isNotEmpty) Text(email),
                      Text(
                        active ? 'الحساب نشط' : 'الحساب موقوف',
                        style: TextStyle(
                          color: active ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: isAvailable,
                    onChanged: active
                        ? (value) async {
                            try {
                              await doc.reference.update({
                                'isAvailable': value,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('تعذر تحديث حالة السائق: $e')),
                              );
                            }
                          }
                        : null,
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
