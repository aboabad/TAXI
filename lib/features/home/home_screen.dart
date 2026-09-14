import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/features/home/restaurant_details_screen.dart';
import 'package:taxi/features/orders/my_orders_screen.dart';
import 'package:taxi/features/profile/profile_screen.dart';
import 'package:taxi/features/wallet/wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _search = '';
  String _category = 'الكل';

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
      );
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WalletScreen()),
      );
      return;
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taxi Taste')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'ابحث عن مطعمك المفضل...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=800&q=60',
                  ),
                  fit: BoxFit.cover,
                  opacity: 0.6,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'اطلب من مطعمك المفضل',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'اختر الوجبات وأرسل طلبك مباشرة',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الأقسام',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _categoryChip('الكل', Icons.grid_view_rounded),
                  _categoryChip('مطاعم', Icons.restaurant),
                  _categoryChip('كافيهات', Icons.coffee),
                  _categoryChip('سريع', Icons.fastfood),
                  _categoryChip('بيتزا', Icons.local_pizza),
                  _categoryChip('حلويات', Icons.icecream),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'المطاعم المتاحة',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('restaurants').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('حدث خطأ أثناء تحميل المطاعم: ${snapshot.error}'),
                  );
                }

                final restaurants = (snapshot.data?.docs ?? []).where((doc) {
                  final data = doc.data();
                  final status = data['status']?.toString() ?? 'pending';
                  final verified = data['verified'] == true;
                  if (status != 'active' || !verified) return false;

                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final category = data['category']?.toString() ?? '';
                  final matchesSearch = _search.isEmpty || name.contains(_search);
                  final matchesCategory =
                      _category == 'الكل' || category == _category;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (restaurants.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('لا توجد مطاعم مطابقة حالياً')),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final doc = restaurants[index];
                    final data = doc.data();
                    final name = data['name']?.toString() ?? 'مطعم';
                    final rawUrl = data['imageUrl']?.toString() ?? '';
                    const defaultImage =
                        'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=60';
                    final imageUrl = rawUrl.trim().isEmpty ? defaultImage : rawUrl;
                    final rating = (data['rating'] as num? ?? 0).toDouble();
                    final category = data['category']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RestaurantDetailsScreen(
                              restaurantId: doc.id,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 150,
                              width: double.infinity,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.restaurant,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      if (rating > 0) ...[
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber[700],
                                          size: 16,
                                        ),
                                        Text(' ${rating.toStringAsFixed(1)}'),
                                        const SizedBox(width: 12),
                                      ],
                                      if (category.isNotEmpty)
                                        Text(
                                          category,
                                          style: const TextStyle(color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'طلباتي'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'المحفظة',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, IconData icon) {
    final selected = _category == label;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ChoiceChip(
        avatar: Icon(
          icon,
          size: 18,
          color: selected ? Colors.white : AppTheme.primaryColor,
        ),
        label: Text(label),
        selected: selected,
        selectedColor: AppTheme.primaryColor,
        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
        onSelected: (_) => setState(() => _category = label),
      ),
    );
  }
}
