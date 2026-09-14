import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _filterRole = 'all';

  static const Map<String, String> _roleNames = {
    'user': 'عميل',
    'driver': 'سائق',
    'restaurant': 'مطعم',
    'moderator': 'مشرف',
    'admin': 'مدير',
  };

  Future<void> _showAccountActions(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data() ?? {};
    final balanceController = TextEditingController(
      text: (data['balance'] as num? ?? 0).toString(),
    );
    var role = data['role']?.toString() ?? 'user';
    if (!_roleNames.containsKey(role)) role = 'user';
    var active = data['active'] != false;
    var saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  data['name']?.toString() ?? data['email']?.toString() ?? 'مستخدم',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'نوع الحساب'),
                  items: _roleNames.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setSheetState(() => role = value);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: balanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'الرصيد',
                    suffixText: 'د.أ',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الحساب نشط'),
                  value: active,
                  onChanged: (value) => setSheetState(() => active = value),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setSheetState(() => saving = true);
                          try {
                            await doc.reference.update({
                              'role': role,
                              'balance': double.tryParse(balanceController.text.trim()) ?? 0,
                              'active': active,
                              'updatedAt': FieldValue.serverTimestamp(),
                            });
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                          } catch (e) {
                            setSheetState(() => saving = false);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('تعذر حفظ الحساب: $e')),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ التغييرات'),
                ),
              ],
            ),
          );
        },
      ),
    );

    balanceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحسابات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: {
                'all': 'الكل',
                ..._roleNames,
              }.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: _filterRole == entry.key,
                    onSelected: (_) => setState(() => _filterRole = entry.key),
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('تعذر تحميل الحسابات: ${snapshot.error}'));
                }

                final users = (snapshot.data?.docs ?? []).where((doc) {
                  if (_filterRole == 'all') return true;
                  return doc.data()['role']?.toString() == _filterRole;
                }).toList();

                users.sort((a, b) {
                  final an = a.data()['name']?.toString() ?? '';
                  final bn = b.data()['name']?.toString() ?? '';
                  return an.compareTo(bn);
                });

                if (users.isEmpty) {
                  return const Center(child: Text('لا توجد حسابات ضمن هذا التصنيف'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final doc = users[index];
                    final user = doc.data();
                    final role = user['role']?.toString() ?? 'user';
                    final active = user['active'] != false;
                    final balance = (user['balance'] as num? ?? 0).toDouble();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(
                            role == 'driver'
                                ? Icons.drive_eta
                                : role == 'restaurant'
                                    ? Icons.restaurant
                                    : role == 'admin'
                                        ? Icons.admin_panel_settings
                                        : Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        title: Text(user['name']?.toString() ?? 'مستخدم'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user['email']?.toString() ?? ''),
                            Text(
                              '${_roleNames[role] ?? role} • ${active ? 'نشط' : 'موقوف'} • ${balance.toStringAsFixed(2)} د.أ',
                              style: TextStyle(
                                color: active ? Colors.green : Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.manage_accounts,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () => _showAccountActions(doc),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
