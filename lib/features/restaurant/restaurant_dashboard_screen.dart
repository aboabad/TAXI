import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/features/admin/add_menu_item_screen.dart';
import 'package:taxi/features/profile/profile_screen.dart';
import 'package:taxi/models/order_model.dart';
import 'package:taxi/services/order_service.dart';

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

class _RestaurantDashboardScreenState extends State<RestaurantDashboardScreen> {
  int _selectedIndex = 0;
  String? _restaurantId;
  bool _loadingRestaurant = true;
  String? _restaurantError;

  @override
  void initState() {
    super.initState();
    _resolveRestaurantId();
  }

  Future<void> _resolveRestaurantId() async {
    if (widget.restaurantId != null && widget.restaurantId!.trim().isNotEmpty) {
      setState(() {
        _restaurantId = widget.restaurantId!.trim();
        _loadingRestaurant = false;
      });
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loadingRestaurant = false;
        _restaurantError = 'يجب تسجيل الدخول أولاً';
      });
      return;
    }

    try {
      final restaurants = FirebaseFirestore.instance.collection('restaurants');

      final byUid = await restaurants
          .where('ownerUid', isEqualTo: user.uid)
          .limit(1)
          .get();
      if (byUid.docs.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _restaurantId = byUid.docs.first.id;
          _loadingRestaurant = false;
        });
        return;
      }

      final email = user.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty) {
        final byEmail = await restaurants
            .where('ownerUsername', isEqualTo: email)
            .limit(1)
            .get();
        if (byEmail.docs.isNotEmpty) {
          if (!mounted) return;
          setState(() {
            _restaurantId = byEmail.docs.first.id;
            _loadingRestaurant = false;
          });
          return;
        }
      }

      final sameId = await restaurants.doc(user.uid).get();
      if (sameId.exists) {
        if (!mounted) return;
        setState(() {
          _restaurantId = sameId.id;
          _loadingRestaurant = false;
        });
        return;
      }

      if (!mounted) return;
      setState(() {
        _loadingRestaurant = false;
        _restaurantError =
            'لم يتم ربط هذا الحساب بأي مطعم. حدّث ownerUid أو بريد مسؤول المطعم من لوحة الإدارة.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRestaurant = false;
        _restaurantError = 'تعذر تحديد المطعم: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingRestaurant) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurantId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('لوحة تحكم المطعم')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _restaurantError ?? 'لم يتم تحديد المطعم',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم المطعم'),
        centerTitle: true,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildOrdersTab(),
          _buildMenuTab(),
          _buildAnalyticsTab(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: AppTheme.primaryColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'الطلبات'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'المنيو',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'التحليلات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    final orderService = Provider.of<OrderService>(context, listen: false);

    return StreamBuilder<List<OrderModel>>(
      stream: orderService.streamRestaurantOrders(_restaurantId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'تعذر تحميل الطلبات:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text('لا توجد طلبات للمطعم حالياً'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'طلب #${order.id.length > 8 ? order.id.substring(0, 8) : order.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _statusChip(order.status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text('عدد الأصناف: ${order.items.length}'),
                    Text('الإجمالي: ${order.totalPrice.toStringAsFixed(2)} د.أ'),
                    if (order.status == OrderStatus.pending) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => orderService.updateOrderStatus(
                                order.id,
                                OrderStatus.cancelled,
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => orderService.updateOrderStatus(
                                order.id,
                                OrderStatus.restaurantAccepted,
                              ),
                              child: const Text('قبول'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusChip(OrderStatus status) {
    late final String text;
    late final Color color;

    switch (status) {
      case OrderStatus.pending:
        text = 'بانتظار المطعم';
        color = Colors.orange;
      case OrderStatus.restaurantAccepted:
        text = 'بانتظار السائق';
        color = Colors.blue;
      case OrderStatus.accepted:
        text = 'تم تعيين سائق';
        color = Colors.indigo;
      case OrderStatus.preparing:
        text = 'تحضير';
        color = Colors.purple;
      case OrderStatus.onTheWay:
        text = 'في الطريق';
        color = Colors.teal;
      case OrderStatus.delivered:
        text = 'مكتمل';
        color = Colors.green;
      case OrderStatus.cancelled:
        text = 'ملغي';
        color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMenuItemScreen(
                    restaurantId: _restaurantId!,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('إضافة صنف جديد'),
          ),
          const SizedBox(height: 20),
          const Text(
            'الأصناف الحالية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('menu_items')
                  .where('restaurantId', isEqualTo: _restaurantId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد أصناف مضافة حتى الآن'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final name = data['name']?.toString() ?? 'صنف بدون اسم';
                    final price = (data['price'] as num? ?? 0).toDouble();
                    final imageUrl = data['imageUrl']?.toString() ?? '';
                    final category = data['category']?.toString() ?? '';

                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _menuPlaceholder(),
                              )
                            : _menuPlaceholder(),
                      ),
                      title: Text(name),
                      subtitle: Text(
                        '${price.toStringAsFixed(2)} د.أ${category.isEmpty ? '' : ' • $category'}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => doc.reference.delete(),
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

  Widget _menuPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.shade300,
      child: const Icon(Icons.fastfood),
    );
  }

  Widget _buildAnalyticsTab() {
    final orderService = Provider.of<OrderService>(context, listen: false);
    return StreamBuilder<List<OrderModel>>(
      stream: orderService.streamRestaurantOrders(_restaurantId!),
      builder: (context, snapshot) {
        final orders = snapshot.data ?? [];
        final delivered = orders
            .where((order) => order.status == OrderStatus.delivered)
            .toList();
        final revenue = delivered.fold<double>(
          0,
          (sum, order) => sum + order.restaurantNetAmount,
        );

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تحليلات الأداء',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _analyticsCard(
                      'العوائد',
                      '${revenue.toStringAsFixed(2)} د.أ',
                      Icons.payments,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _analyticsCard(
                      'الطلبات',
                      '${orders.length}',
                      Icons.event_available,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
