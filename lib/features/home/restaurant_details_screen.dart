import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/features/orders/booking_invoice_screen.dart';
import 'package:taxi/models/order_model.dart';
import 'package:taxi/services/order_service.dart';

class RestaurantDetailsScreen extends StatefulWidget {
  final String? restaurantId;

  const RestaurantDetailsScreen({
    super.key,
    this.restaurantId,
  });

  @override
  State<RestaurantDetailsScreen> createState() => _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  final Map<String, Map<String, dynamic>> _selectedItems = {};
  String _selectedCategory = 'الكل';
  bool _submitting = false;

  String get _effectiveRestaurantId => widget.restaurantId ?? '';

  double get _foodTotal {
    var total = 0.0;
    for (final item in _selectedItems.values) {
      final price = (item['price'] as num? ?? 0).toDouble();
      final quantity = (item['quantity'] as num? ?? 1).toInt();
      total += price * quantity;
    }
    return total;
  }

  int get _totalItemsCount {
    var count = 0;
    for (final item in _selectedItems.values) {
      count += (item['quantity'] as num? ?? 1).toInt();
    }
    return count;
  }

  void _updateItemQuantity(String id, String title, double price, int change) {
    setState(() {
      final current = _selectedItems[id];
      if (current == null) {
        if (change > 0) {
          _selectedItems[id] = {
            'id': id,
            'name': title,
            'price': price,
            'quantity': 1,
          };
        }
        return;
      }

      final currentQty = (current['quantity'] as num? ?? 1).toInt();
      final newQty = currentQty + change;
      if (newQty <= 0) {
        _selectedItems.remove(id);
      } else {
        current['quantity'] = newQty;
      }
    });
  }

  Future<void> _submitOrder(
    String restaurantName,
    Map<String, dynamic> restaurantData,
  ) async {
    if (_submitting || _selectedItems.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول لإرسال الطلب')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final commissionRate =
          (restaurantData['commissionRate'] as num? ?? 0.10).toDouble();
      final restaurantCommission = _foodTotal * commissionRate;

      final order = OrderModel(
        id: '',
        userId: user.uid,
        restaurantId: _effectiveRestaurantId,
        restaurantName: restaurantName,
        peopleCount: 1,
        bookingDate: DateTime.now(),
        bookingDuration: 1,
        items: _selectedItems.values
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
        restaurantPrice: _foodTotal,
        roundTripDeliveryPrice: 0,
        discount: 0,
        foodTotal: _foodTotal,
        subtotal: _foodTotal,
        totalPrice: _foodTotal,
        restaurantCommissionRate: commissionRate,
        restaurantCommission: restaurantCommission,
        restaurantNetAmount: _foodTotal - restaurantCommission,
        driverCommissionRate: 0,
        driverCommission: 0,
        driverNetAmount: 0,
        adminRevenue: restaurantCommission,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      final orderService = Provider.of<OrderService>(context, listen: false);
      final orderId = await orderService.createOrder(order);

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BookingInvoiceScreen(
            restaurantName: restaurantName,
            bookingId: orderId,
            peopleCount: order.peopleCount,
            bookingDate: order.bookingDate,
            status: 'قيد انتظار موافقة المطعم',
            totalPrice: order.totalPrice,
          ),
        ),
      );

      if (mounted) {
        setState(() => _selectedItems.clear());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر إرسال الطلب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_effectiveRestaurantId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('لم يتم العثور على معرّف المطعم')),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_effectiveRestaurantId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            debugPrint('خطأ جلب بيانات المطعم: ${snapshot.error}');
          }
          return Scaffold(
            body: Center(child: Text('حدث خطأ: ${snapshot.error}')),
          );
        }

        final restaurantData = snapshot.data?.data();
        if (restaurantData == null) {
          return const Scaffold(
            body: Center(child: Text('المطعم غير موجود')),
          );
        }

        final restaurantName = restaurantData['name']?.toString() ?? 'مطعم';
        final restaurantCategory =
            restaurantData['category']?.toString() ?? 'عام';
        final rawImageUrl = restaurantData['imageUrl']?.toString() ?? '';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    restaurantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  background: _buildHeaderImage(rawImageUrl),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurantName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurantCategory,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        '📋 قائمة الطعام',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildCategoryFilterBar(),
                      const SizedBox(height: 12),
                      _buildMenuList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _selectedItems.isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'العناصر ($_totalItemsCount): ${_foodTotal.toStringAsFixed(2)} د.أ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _submitting
                                ? null
                                : () => _submitOrder(
                                      restaurantName,
                                      restaurantData,
                                    ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('إرسال الطلب'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildHeaderImage(String url) {
    if (url.trim().isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.restaurant, size: 80, color: Colors.grey),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    const categories = ['الكل', 'مأكولات', 'مشروبات', 'حلويات', 'عروض'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = _selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = category);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuList() {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('menu_items')
        .where('restaurantId', isEqualTo: _effectiveRestaurantId);

    if (_selectedCategory != 'الكل') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('حدث خطأ أثناء تحميل المنيو: ${snapshot.error}'),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'لا توجد وجبات في هذا التصنيف حالياً',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (_, _) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final item = doc.data();
            final id = doc.id;
            final title = item['name']?.toString() ?? 'وجبة';
            final price = (item['price'] as num? ?? 0).toDouble();
            final imageUrl = item['imageUrl']?.toString() ?? '';
            final qty =
                (_selectedItems[id]?['quantity'] as num? ?? 0).toInt();

            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl.trim().isNotEmpty
                        ? Image.network(
                            imageUrl,
                            height: 60,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _imageFallback(),
                          )
                        : _imageFallback(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${price.toStringAsFixed(2)} د.أ',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (qty > 0) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () =>
                              _updateItemQuantity(id, title, price, -1),
                        ),
                        Text(
                          '$qty',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: Colors.green,
                        ),
                        onPressed: () =>
                            _updateItemQuantity(id, title, price, 1),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.grey.shade300,
      height: 60,
      width: 60,
      child: const Icon(Icons.fastfood),
    );
  }
}
