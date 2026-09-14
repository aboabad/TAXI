import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/features/admin/add_menu_item_screen.dart';
import 'package:taxi/features/profile/profile_screen.dart';

class RestaurantDashboardScreen extends StatefulWidget {
  final String? restaurantId;

  const RestaurantDashboardScreen({
    super.key,
    this.restaurantId,
  });

  @override
  State<RestaurantDashboardScreen> createState() =>
      _RestaurantDashboardScreenState();
}

class _RestaurantDashboardScreenState
    extends State<RestaurantDashboardScreen> {
  int _selectedIndex = 0;
  late String effectiveRestaurantId;

  @override
  void initState() {
    super.initState();
    // 👈 إذا لم يتم تمرير معرف المطعم من الشاشة السابقة، يتم اعتماده من المستخدم الحالي تلقائياً
    effectiveRestaurantId = widget.restaurantId ??
        FirebaseAuth.instance.currentUser?.uid ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المطعم'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 👈 في حال تعذر الحصول على معرف المطعم من الحساب نهائياً، يظهر شريط تنبيه تنبيهي
          if (effectiveRestaurantId.isEmpty)
            Container(
              color: Colors.red,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: const Text(
                'لم يتم تحديد معرف المطعم. يرجى إعادة تسجيل الدخول',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildOrdersTab(),
                _buildMenuTab(),
                _buildAnalyticsTab(),
                const ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'الحجوزات'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'المنيو'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التحليلات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('حجز طاولة - 4 أشخاص',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('انتظار',
                          style: TextStyle(color: Colors.orange, fontSize: 12)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('العميل: محمد علي'),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text('التوقيت: اليوم - 08:30 م'),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red),
                        child: const Text('رفض'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text('قبول'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: () {
              if (effectiveRestaurantId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMenuItemScreen(
                      restaurantId: effectiveRestaurantId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('لم يتم تحديد معرف المطعم'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة صنف جديد'),
          ),
          const SizedBox(height: 24),
          const Text('الأصناف الحالية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: effectiveRestaurantId.isEmpty
                ? const Center(child: Text('يرجى تحديد المطعم لعرض الأصناف'))
                : StreamBuilder<QuerySnapshot>(
              // 👈 ربط حقيقي بـ Firestore بجلب أصناف المطعم فقط
              stream: FirebaseFirestore.instance
                  .collection('menu_items')
                  .where('restaurantId', isEqualTo: effectiveRestaurantId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد أصناف مضافة حتى الآن'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String title = data['name'] ?? 'صنف بدون اسم';
                    final String price = '${data['price'] ?? 0} د.أ';
                    final String imageUrl = data['imageUrl'] ?? '';

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.fastfood),
                          ),
                        )
                            : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(Icons.fastfood),
                        ),
                      ),
                      title: Text(title),
                      subtitle: Text(price),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {},
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

  Widget _buildAnalyticsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحليلات الأداء اليومي',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _analyticsCard(
                      'العوائد', '2,450 د.أ', Icons.payments, Colors.green)),
              const SizedBox(width: 16),
              Expanded(
                  child: _analyticsCard(
                      'الحجوزات', '15', Icons.event_available, Colors.blue)),
            ],
          ),
          const SizedBox(height: 24),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('إحصائيات المستخدمين',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(
                      height: 40,
                      child: Center(child: Text('رسم بياني (Placeholder)'))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analyticsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.black54)),
          Text(value,
              style:
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}