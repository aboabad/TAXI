import 'package:cloud_firestore/cloud_firestore.dart';
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
  final RestaurantService _service = RestaurantService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المطاعم'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<RestaurantModel>>(
        stream: _service.streamRestaurants(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'حدث خطأ أثناء تحميل المطاعم:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final restaurants = snapshot.data ?? [];
          if (restaurants.isEmpty) {
            return const Center(child: Text('لا توجد مطاعم حالياً'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) =>
                _restaurantCard(restaurants[index]),
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

  Widget _restaurantCard(RestaurantModel restaurant) {
    final (statusText, statusColor) = switch (restaurant.status) {
      RestaurantStatus.active => ('نشط', Colors.green),
      RestaurantStatus.pending => ('بانتظار الموافقة', Colors.orange),
      RestaurantStatus.suspended => ('موقوف مؤقتاً', Colors.deepOrange),
      RestaurantStatus.blocked => ('محظور', Colors.red),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: const Icon(Icons.restaurant, color: AppTheme.primaryColor),
        ),
        title: Text(
          restaurant.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (restaurant.category.isNotEmpty) Text(restaurant.category),
            if (restaurant.ownerUsername.isNotEmpty)
              Text('المسؤول: ${restaurant.ownerUsername}'),
            Text(statusText, style: TextStyle(color: statusColor)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(value, restaurant),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('تعديل')),
            PopupMenuItem(value: 'dashboard', child: Text('لوحة المطعم')),
            PopupMenuItem(value: 'menu', child: Text('إضافة صنف')),
            PopupMenuItem(value: 'approve', child: Text('تفعيل')),
            PopupMenuItem(value: 'suspend', child: Text('إيقاف مؤقت')),
            PopupMenuItem(value: 'block', child: Text('حظر')),
            PopupMenuItem(value: 'delete', child: Text('حذف')),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    String action,
    RestaurantModel restaurant,
  ) async {
    try {
      switch (action) {
        case 'edit':
          await _showRestaurantDialog(restaurant: restaurant);
          return;
        case 'dashboard':
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RestaurantDashboardScreen(restaurantId: restaurant.id),
            ),
          );
          return;
        case 'menu':
          if (!mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddMenuItemScreen(restaurantId: restaurant.id),
            ),
          );
          return;
        case 'approve':
          await _service.approveRestaurant(restaurant.id);
          break;
        case 'suspend':
          await _service.suspendRestaurant(restaurant.id);
          break;
        case 'block':
          await _service.blockRestaurant(restaurant.id);
          break;
        case 'delete':
          if (!mounted) return;
          final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('حذف المطعم'),
                  content: Text('هل تريد حذف ${restaurant.name}؟'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('إلغاء'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('حذف'),
                    ),
                  ],
                ),
              ) ??
              false;
          if (confirmed) await _service.deleteRestaurant(restaurant.id);
          break;
      }
    } catch (e) {
      _showMessage('تعذر تنفيذ العملية: $e', Colors.red);
    }
  }

  Future<String> _resolveOwnerUid(String ownerEmail) async {
    final email = ownerEmail.trim().toLowerCase();
    if (email.isEmpty) return '';

    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return query.docs.isEmpty ? '' : query.docs.first.id;
  }

  Future<void> _showRestaurantDialog({RestaurantModel? restaurant}) async {
    final isEditing = restaurant != null;
    final nameController = TextEditingController(text: restaurant?.name ?? '');
    final categoryController =
        TextEditingController(text: restaurant?.category ?? '');
    final ownerController =
        TextEditingController(text: restaurant?.ownerUsername ?? '');
    final tablesController = TextEditingController(
      text: (restaurant?.tablesCount ?? 0).toString(),
    );
    final commissionController = TextEditingController(
      text: ((restaurant?.commissionRate ?? 0.10) * 100).toStringAsFixed(0),
    );

    LatLng? selectedLocation =
        restaurant?.latitude != null && restaurant?.longitude != null
            ? LatLng(restaurant!.latitude!, restaurant.longitude!)
            : null;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var saving = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'تعديل المطعم' : 'إضافة مطعم'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'اسم المطعم'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(labelText: 'التصنيف'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: ownerController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'بريد حساب مسؤول المطعم',
                          hintText: 'restaurant@example.com',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: tablesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'عدد الطاولات'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: commissionController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'عمولة الإدارة من المطعم (%)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: selectedLocation ??
                                const LatLng(31.9454, 35.9284),
                            zoom: 12,
                          ),
                          onTap: (location) => setDialogState(
                            () => selectedLocation = location,
                          ),
                          markers: selectedLocation == null
                              ? <Marker>{}
                              : {
                                  Marker(
                                    markerId: const MarkerId('restaurant'),
                                    position: selectedLocation!,
                                  ),
                                },
                          myLocationButtonEnabled: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final category = categoryController.text.trim();
                          final ownerEmail = ownerController.text.trim().toLowerCase();
                          final tables = int.tryParse(tablesController.text.trim()) ?? 0;
                          final percent =
                              double.tryParse(commissionController.text.trim()) ?? 10;

                          if (name.isEmpty) {
                            _showMessage('يرجى إدخال اسم المطعم', Colors.red);
                            return;
                          }
                          if (percent < 0 || percent > 100) {
                            _showMessage('العمولة يجب أن تكون بين 0 و100', Colors.red);
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            final ownerUid = ownerEmail.isEmpty
                                ? (restaurant?.ownerUid ?? '')
                                : await _resolveOwnerUid(ownerEmail);

                            if (ownerEmail.isNotEmpty && ownerUid.isEmpty) {
                              throw Exception(
                                'لا يوجد مستخدم مسجل بهذا البريد. أنشئ الحساب أولاً ثم اربطه بالمطعم.',
                              );
                            }

                            final model = RestaurantModel(
                              id: restaurant?.id ?? '',
                              name: name,
                              category: category,
                              ownerUid: ownerUid,
                              ownerUsername: ownerEmail,
                              address: restaurant?.address ?? '',
                              description: restaurant?.description ?? '',
                              imageUrl: restaurant?.imageUrl ?? '',
                              rating: restaurant?.rating ?? 0,
                              verified: restaurant?.verified ?? false,
                              status: restaurant?.status ?? RestaurantStatus.pending,
                              commissionRate: percent / 100,
                              tablesCount: tables,
                              availableTables: isEditing
                                  ? (restaurant.availableTables > tables
                                      ? tables
                                      : restaurant.availableTables)
                                  : tables,
                              latitude: selectedLocation?.latitude,
                              longitude: selectedLocation?.longitude,
                              createdAt: restaurant?.createdAt ?? DateTime.now(),
                            );

                            if (isEditing) {
                              await _service.updateRestaurant(
                                restaurant.id,
                                model.toMap(),
                              );
                            } else {
                              await _service.createRestaurant(model);
                            }

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            _showMessage('تم حفظ بيانات المطعم', Colors.green);
                          } catch (e) {
                            setDialogState(() => saving = false);
                            _showMessage('$e', Colors.red);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('حفظ'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    categoryController.dispose();
    ownerController.dispose();
    tablesController.dispose();
    commissionController.dispose();
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}
