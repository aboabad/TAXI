import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/core/auth_service.dart';
import 'package:taxi/features/chat/chat_screen.dart';
import 'package:taxi/models/order_model.dart';
import 'package:taxi/services/location_service.dart';
import 'package:taxi/services/order_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;

  const OrderTrackingScreen({
    super.key,
    required this.order,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final LocationService _locationService = LocationService();

  StreamSubscription? _driverLocationSubscription;
  GoogleMapController? _mapController;

  late OrderModel _order;
  LatLng? _driverPosition;
  LatLng? _restaurantPosition;
  bool _updatingStatus = false;

  static const LatLng _defaultLocation = LatLng(31.9454, 35.9284);

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadRestaurantLocation();
    _listenToDriverLocation();
  }

  @override
  void dispose() {
    _driverLocationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadRestaurantLocation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_order.restaurantId)
          .get();
      final data = doc.data();
      final latitude = (data?['latitude'] as num?)?.toDouble();
      final longitude = (data?['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null || !mounted) return;

      final position = LatLng(latitude, longitude);
      setState(() => _restaurantPosition = position);
      _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    } catch (e) {
      debugPrint('Restaurant location error: $e');
    }
  }

  void _listenToDriverLocation() {
    final driverId = _order.driverId;
    if (driverId == null || driverId.trim().isEmpty) return;

    _driverLocationSubscription = _locationService
        .streamDriverLocation(driverId)
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final raw = snapshot.data();
      if (raw is! Map<String, dynamic>) return;

      final latitude = (raw['latitude'] as num?)?.toDouble();
      final longitude = (raw['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) return;

      final position = LatLng(latitude, longitude);
      if (!mounted) return;

      setState(() => _driverPosition = position);
      _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }, onError: (error) {
      debugPrint('Driver location stream error: $error');
    });
  }

  Future<void> _updateStatus(OrderStatus status) async {
    if (_updatingStatus) return;

    setState(() => _updatingStatus = true);
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.updateOrderStatus(
        _order.id,
        status,
        driverId: _order.driverId,
      );

      if (!mounted) return;
      setState(() {
        _order = _order.copyWith(status: status);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_statusText(status))),
      );

      if (status == OrderStatus.delivered && mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء تحديث الطلب:\n$e')),
      );
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  String _statusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'الطلب قيد انتظار المطعم';
      case OrderStatus.restaurantAccepted:
        return 'المطعم وافق والطلب بانتظار سائق';
      case OrderStatus.accepted:
        return 'تم قبول الطلب من السائق';
      case OrderStatus.preparing:
        return 'الطلب قيد التحضير';
      case OrderStatus.onTheWay:
        return 'الطلب في الطريق';
      case OrderStatus.delivered:
        return 'تم توصيل الطلب بنجاح';
      case OrderStatus.cancelled:
        return 'تم إلغاء الطلب';
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          infoWindow: const InfoWindow(title: 'موقع السائق'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    markers.add(
      Marker(
        markerId: const MarkerId('restaurant'),
        position: _restaurantPosition ?? _defaultLocation,
        infoWindow: InfoWindow(title: _order.restaurantName),
      ),
    );

    return markers;
  }

  void _openChat() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.user == null || _order.userId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: _order.id,
          receiverId: _order.userId,
          receiverName: 'العميل',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تتبع الطلب'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _restaurantPosition ?? _defaultLocation,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            compassEnabled: true,
            mapType: MapType.normal,
            markers: _buildMarkers(),
            onMapCreated: (controller) {
              _mapController = controller;
              final target = _driverPosition ?? _restaurantPosition;
              if (target != null) {
                controller.animateCamera(CameraUpdate.newLatLng(target));
              }
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'العميل',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'طلب رقم: ${_order.id}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.message,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: _openChat,
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: _infoItem(
                            title: 'أجرة التوصيل',
                            value:
                                '${_order.roundTripDeliveryPrice.toStringAsFixed(2)} د.أ',
                            icon: Icons.local_shipping,
                          ),
                        ),
                        Expanded(
                          child: _infoItem(
                            title: 'مستحق السائق',
                            value: '${_order.driverNetAmount.toStringAsFixed(2)} د.أ',
                            icon: Icons.payments,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _infoItem(
                            title: 'عمولة الإدارة',
                            value:
                                '${_order.driverCommission.toStringAsFixed(2)} د.أ',
                            icon: Icons.account_balance,
                          ),
                        ),
                        Expanded(
                          child: _infoItem(
                            title: 'حالة الطلب',
                            value: _statusText(_order.status),
                            icon: Icons.info_outline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_order.status == OrderStatus.accepted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updatingStatus
                              ? null
                              : () => _updateStatus(OrderStatus.onTheWay),
                          child: _updatingStatus
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('بدء التوصيل'),
                        ),
                      ),
                    if (_order.status == OrderStatus.onTheWay)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updatingStatus
                              ? null
                              : () => _updateStatus(OrderStatus.delivered),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 55),
                          ),
                          child: _updatingStatus
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('تم توصيل الطلب'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppTheme.primaryColor),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
