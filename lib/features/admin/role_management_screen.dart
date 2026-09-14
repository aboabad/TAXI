import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

class RoleModel {
  final String name;
  final List<String> permissions;

  RoleModel({required this.name, required this.permissions});
}

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final List<RoleModel> _roles = [
    RoleModel(name: 'مشرف رئيسي', permissions: ['الكل']),
    RoleModel(name: 'مدير عمليات', permissions: ['إدارة الحجوزات', 'تتبع السائقين']),
    RoleModel(name: 'دعم فني', permissions: ['الإشعارات', 'مركز المساعدة']),
  ];

  final List<String> _availablePermissions = [
    'إدارة الفئات',
    'إدارة المستخدمين',
    'إدارة السائقين',
    'إدارة المطاعم',
    'الإشعارات',
    'إدارة الحجوزات',
    'الأدوار',
    'المطاعم',
    'التحليلات',
    'تتبع السواقين',
  ];

  void _showAddRoleDialog() {
    String newRoleName = '';
    List<String> selectedPermissions = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة دور جديد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(hintText: 'اسم الدور (مثلاً: مراقب)'),
                  onChanged: (value) => newRoleName = value,
                ),
                const SizedBox(height: 16),
                const Text('الصلاحيات:', style: TextStyle(fontWeight: FontWeight.bold)),
                ..._availablePermissions.map((perm) => CheckboxListTile(
                      title: Text(perm, style: const TextStyle(fontSize: 14)),
                      value: selectedPermissions.contains(perm),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val!) {
                            selectedPermissions.add(perm);
                          } else {
                            selectedPermissions.remove(perm);
                          }
                        });
                      },
                      dense: true,
                      controlAffinity: ListTileControlAffinity.leading,
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (newRoleName.isNotEmpty) {
                  setState(() {
                    _roles.add(RoleModel(name: newRoleName, permissions: selectedPermissions));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الأدوار والصلاحيات'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _roles.length,
        itemBuilder: (context, index) {
          final role = _roles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: const CircleAvatar(
                backgroundColor: AppTheme.secondaryColor,
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${role.permissions.length} صلاحيات'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: role.permissions
                            .map((p) => Chip(
                                  label: Text(p, style: const TextStyle(fontSize: 12)),
                                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('تعديل'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _roles.removeAt(index));
                            },
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text('حذف', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRoleDialog,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('إضافة دور', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
