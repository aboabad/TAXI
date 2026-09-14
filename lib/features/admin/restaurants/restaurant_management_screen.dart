import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/features/admin/add_menu_item_screen.dart';
import 'package:taxi/features/restaurant/restaurant_dashboard_screen.dart';
import 'package:taxi/models/restaurant_model.dart';
import 'package:taxi/services/restaurant_service.dart';

class RestaurantManagementScreen extends StatefulWidget {
  const RestaurantManagementScreen({super.key});

  @override
  State<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _RestaurantManagementScreenState
    extends State<RestaurantManagementScreen> {
  final RestaurantService _restaurantService = RestaurantService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المطاعم'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<RestaurantModel>>(
        stream: _restaurantService.streamRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'حدث خطأ أثناء تحميل المطاعم',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final restaurants = snapshot.data ?? [];
          if (restaurants.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              return _buildRestaurantCard(restaurants[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRestaurantDialog(),
        icon: const Icon(Icons.add),
        label: const Text('إضافة مطعم'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_outlined,
              size: 70, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text('لا توجد مطاعم حالياً',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRestaurantCard(RestaurantModel restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(Icons.restaurant, color: AppTheme.primaryColor),
        ),
        title: Text(restaurant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (restaurant.category.isNotEmpty)
                Text(restaurant.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (restaurant.ownerUsername.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      'المسؤول: ${restaurant.ownerUsername}',
                      style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 5),
              Row(
                children: [
                  _buildStatusText(restaurant),
                  const SizedBox(width: 10),
                  if (restaurant.rating > 0) ...[
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(restaurant.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ],
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showRestaurantActions(restaurant),
        ),
      ),
    );
  }

  Widget _buildStatusText(RestaurantModel restaurant) {
    String text = 'نشط';
    Color color = Colors.green;
    if (restaurant.status == RestaurantStatus.pending) {
      text = 'بانتظار الموافقة'; color = Colors.orange;
    } else if (restaurant.status == RestaurantStatus.suspended) {
      text = 'موقوف مؤقتاً'; color = Colors.orange.shade800;
    } else if (restaurant.status == RestaurantStatus.blocked) {
      text = 'محظور'; color = Colors.red;
    }
    return Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold));
  }

  void _showRestaurantActions(RestaurantModel restaurant) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(restaurant.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),

                  _actionButton(
                    icon: Icons.edit_note,
                    title: 'تعديل بيانات المطعم والمستخدم',
                    color: Colors.purple,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _showRestaurantDialog(restaurant: restaurant);
                    },
                  ),

                  _actionButton(
                    icon: Icons.dashboard,
                    title: 'لوحة تحكم المطعم والطلبات',
                    color: AppTheme.primaryColor,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDashboardScreen(restaurantId: restaurant.id),
                        ),
                      );
                    },
                  ),

                  _actionButton(
                    icon: Icons.restaurant_menu,
                    title: 'إضافة أصناف إلى المنيو',
                    color: Colors.orange,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMenuItemScreen(restaurantId: restaurant.id),
                        ),
                      );
                    },
                  ),

                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                    label: const Text('إغلاق'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  void _showRestaurantDialog({RestaurantModel? restaurant}) {
    final isEditing = restaurant != null;
    final nameController = TextEditingController(text: restaurant?.name ?? '');
    final categoryController = TextEditingController(text: restaurant?.category ?? '');
    final ownerController = TextEditingController(text: restaurant?.ownerUsername ?? '');
    final tablesController = TextEditingController(text: (restaurant?.tablesCount ?? 0).toString());

    // تعريف الـ Controller الخاص بالنسبة المئوية (الافتراضي 10 أو القيمة المحفوظة كمئوية مثلاً 10% -> 0.10)
    final commissionController = TextEditingController(
      text: restaurant != null ? (restaurant.commissionRate * 100).toStringAsFixed(0) : '10',
    );

    LatLng? selectedLocation = (restaurant?.latitude != null && restaurant?.longitude != null)
        ? LatLng(restaurant!.latitude!, restaurant.longitude!)
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'تعديل بيانات المطعم' : 'إضافة مطعم جديد', textAlign: TextAlign.center),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'اسم المطعم',
                          prefixIcon: Icon(Icons.restaurant),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'التصنيف',
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ownerController,
                        decoration: const InputDecoration(
                          labelText: 'اسم مستخدم الإدارة (Username/Email)',
                          hintText: 'مثال: manager_rest1',
                          prefixIcon: Icon(Icons.person_pin),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tablesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'عدد الطاولات',
                          prefixIcon: Icon(Icons.table_restaurant),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // حقل النسبة المئوية المضاف حديثاً
                      TextField(
                        controller: commissionController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'النسبة المئوية للمطعم (%)',
                          hintText: 'مثال: 10',
                          prefixIcon: Icon(Icons.percent),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'تحديد الموقع على الخريطة (اضغط على المكان)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          height: 220,
                          width: double.infinity,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: selectedLocation ?? const LatLng(31.9454, 35.9284),
                              zoom: 12,
                            ),
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: true,
                            onTap: (LatLng location) {
                              setDialogState(() {
                                selectedLocation = location;
                              });
                            },
                            markers: selectedLocation == null
                                ? {}
                                : {
                              Marker(
                                markerId: const MarkerId('restaurant_location'),
                                position: selectedLocation!,
                                infoWindow: const InfoWindow(title: 'موقع المطعم'),
                              ),
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selectedLocation != null)
                        Text(
                          'الموقع المحدد: ${selectedLocation!.latitude.toStringAsFixed(5)}, ${selectedLocation!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    final name = nameController.text.trim();
                    final category = categoryController.text.trim();
                    final owner = ownerController.text.trim();
                    final tables = int.tryParse(tablesController.text.trim()) ?? 0;

                    // قراءة النسبة وتحويلها إلى قيمة عشرية (مثلاً 10 تصبح 0.10)
                    final commissionInput = double.tryParse(commissionController.text.trim()) ?? 10.0;
                    final commissionRate = commissionInput > 1 ? commissionInput / 100 : commissionInput;

                    if (name.isEmpty) {
                      _showMessage('يرجى إدخال اسم المطعم', Colors.red);
                      return;
                    }

                    setDialogState(() => isSaving = true);

                    try {
                      final restaurantData = RestaurantModel(
                        id: isEditing ? restaurant.id : '',
                        name: name,
                        category: category,
                        ownerUsername: owner,
                        rating: isEditing ? restaurant.rating : 0,
                        verified: isEditing ? restaurant.verified : false,
                        status: isEditing ? restaurant.status : RestaurantStatus.pending,
                        commissionRate: commissionRate, // تمرير النسبة المحددة
                        tablesCount: tables,
                        availableTables: tables,
                        latitude: selectedLocation?.latitude,
                        longitude: selectedLocation?.longitude,
                        createdAt: isEditing ? restaurant.createdAt : DateTime.now(),
                      );

                      if (isEditing) {
                        await _restaurantService.updateRestaurant(
                          restaurant.id,
                          restaurantData.toMap(),
                        );
                      } else {
                        await _restaurantService.createRestaurant(restaurantData);
                      }

                      if (!mounted || !dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _showMessage(isEditing ? 'تم تعديل البيانات بنجاح' : 'تمت إضافة المطعم بنجاح', Colors.green);
                    } catch (e) {
                      if (!mounted || !dialogContext.mounted) return;
                      setDialogState(() => isSaving = false);
                      _showMessage('حدث خطأ: $e', Colors.red);
                    }
                  },
                  child: isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'حفظ التعديلات' : 'إضافة'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }
}