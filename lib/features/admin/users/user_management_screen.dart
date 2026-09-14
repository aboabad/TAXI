import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final List<Map<String, dynamic>> _users = [
    {'name': 'محمد عبدالله', 'email': 'mohamed@example.com', 'type': 'عميل', 'status': 'نشط', 'balance': 150.0},
    {'name': 'أحمد علي', 'email': 'ahmed@driver.com', 'type': 'سائق', 'status': 'نشط', 'balance': 450.0},
    {'name': 'مطعم القصر', 'email': 'palace@rest.com', 'type': 'مطعم', 'status': 'نشط', 'balance': 2500.0},
    {'name': 'سارة عمر', 'email': 'sara@example.com', 'type': 'عميل', 'status': 'محظور', 'balance': 0.0},
  ];

  String _filterType = 'الكل';

  void _showAccountActions(int index) {
    final user = _users[index];
    final TextEditingController balanceController = TextEditingController(text: user['balance'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إدارة حساب: ${user['name']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text('تعديل الرصيد', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'أدخل المبلغ الجديد',
                suffixText: 'د.أ',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _users[index]['balance'] = double.tryParse(balanceController.text) ?? user['balance'];
                });
                Navigator.pop(context);
              },
              child: const Text('تحديث الرصيد'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _users[index]['status'] = user['status'] == 'محظور' ? 'نشط' : 'محظور';
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: user['status'] == 'محظور' ? Colors.blue : Colors.red,
              ),
              child: Text(user['status'] == 'محظور' ? 'إلغاء الحظر' : 'حظر الحساب'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredUsers = _filterType == 'الكل'
        ? _users
        : _users.where((u) => u['type'] == _filterType).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الحسابات'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: ['الكل', 'عميل', 'سائق', 'مطعم'].map((type) {
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(type),
                    selected: _filterType == type,
                    onSelected: (selected) {
                      setState(() => _filterType = type);
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: Icon(
                        user['type'] == 'عميل' ? Icons.person : 
                        user['type'] == 'سائق' ? Icons.drive_eta : Icons.restaurant,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(user['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user['email'], style: const TextStyle(fontSize: 12)),
                        Row(
                          children: [
                            Text(user['status'], style: TextStyle(
                              color: user['status'] == 'نشط' ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold
                            )),
                            const SizedBox(width: 12),
                            Text('الرصيد: ${user['balance']} د.أ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.manage_accounts, color: AppTheme.primaryColor),
                      onPressed: () => _showAccountActions(_users.indexOf(user)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
