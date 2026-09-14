import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';

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

  String get _effectiveRestaurantId => widget.restaurantId ?? '';

  double get _foodTotal {
    double total = 0.0;
    _selectedItems.forEach((key, item) {
      final double price = (item['price'] as num? ?? 0.0).toDouble();
      final int qty = (item['quantity'] as int? ?? 1);
      total += price * qty;
    });
    return total;
  }

  int get _totalItemsCount {
    int count = 0;
    _selectedItems.forEach((key, item) {
      count += (item['quantity'] as int? ?? 1);
    });
    return count;
  }

  void _updateItemQuantity(String id, String title, double price, int change) {
    setState(() {
      if (!_selectedItems.containsKey(id)) {
        if (change > 0) {
          _selectedItems[id] = {
            'id': id,
            'name': title,
            'price': price,
            'quantity': 1,
          };
        }
      } else {
        final currentQty = _selectedItems[id]!['quantity'] as int;
        final newQty = currentQty + change;
        if (newQty <= 0) {
          _selectedItems.remove(id);
        } else {
          _selectedItems[id]!['quantity'] = newQty;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_effectiveRestaurantId.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text('لم يتم العثور على معرّف المطعم (ID فارغ)'),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
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

        final restaurantData = snapshot.data?.data() as Map<String, dynamic>?;
        final restaurantName = restaurantData?['name'] ?? 'تفاصيل المطعم';
        final restaurantCategory = restaurantData?['category'] ?? 'عام';
        final rawImageUrl = restaurantData?['imageUrl'] ?? '';

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(restaurantName, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        restaurantCategory,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      const Text('📋 قائمة الطعام', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'العناصر ($_totalItemsCount): ${_foodTotal.toStringAsFixed(2)} د.أ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () {
                        // إرسال كائن الحجز المكتمل عند الرجوع للشاشة السابقة أو الحجز
                        final orderData = {
                          'restaurantId': _effectiveRestaurantId,
                          'restaurantName': restaurantName,
                          'items': _selectedItems.values.toList(),
                          'totalAmount': _foodTotal,
                          'totalCount': _totalItemsCount,
                        };

                        // الرجوع بالشاشة وتمرير بيانات الطلب للمُستدعي
                        Navigator.pop(context, orderData);
                      },
                      child: const Text('متابعة'),
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
        child: const Center(child: Icon(Icons.restaurant, size: 80, color: Colors.grey)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey.shade300,
        child: const Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
      ),
    );
  }

  Widget _buildCategoryFilterBar() {
    final categories = ['الكل', 'مأكولات', 'مشروبات', 'حلويات', 'عروض'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedCategory = cat);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuList() {
    Query query = FirebaseFirestore.instance
        .collection('menu_items')
        .where('restaurantId', isEqualTo: _effectiveRestaurantId);

    if (_selectedCategory != 'الكل') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            debugPrint('خطأ جلب المنيو: ${snapshot.error}');
          }
          return Center(child: Text('حدث خطأ أثناء تحميل المنيو: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          if (kDebugMode) {
            debugPrint('لا توجد بيانات لـ restaurantId: $_effectiveRestaurantId في التصنيف: $_selectedCategory');
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                'لا توجد وجبات مضافة لهذا المطعم حالياً',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          separatorBuilder: (context, index) => const Divider(height: 16),
          itemBuilder: (context, index) {
            final doc = docs[index];
            final item = doc.data() as Map<String, dynamic>;
            final String id = doc.id;
            final String title = item['name'] ?? 'وجبة';
            final double price = (item['price'] as num? ?? 0.0).toDouble();
            final String imageUrl = item['imageUrl'] ?? '';
            final int qty = (_selectedItems[id]?['quantity'] as int? ?? 0);

            return Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
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
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        height: 60,
                        width: 60,
                        child: const Icon(Icons.fastfood),
                      ),
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      height: 60,
                      width: 60,
                      child: const Icon(Icons.fastfood),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('$price د.أ', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (qty > 0) ...[
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _updateItemQuantity(id, title, price, -1),
                        ),
                        Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => _updateItemQuantity(id, title, price, 1),
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
}