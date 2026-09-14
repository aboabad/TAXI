import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import 'package:taxi/core/app_theme.dart';
import 'package:taxi/core/auth_service.dart';
import 'package:taxi/features/driver/order_tracking_screen.dart';
import 'package:taxi/features/profile/profile_screen.dart';
import 'package:taxi/models/order_model.dart';
import 'package:taxi/services/location_service.dart';
import 'package:taxi/services/order_service.dart';

class DriverHomeScreen extends StatefulWidget {
const DriverHomeScreen({super.key});

@override
State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
bool isOnline = false;
int _selectedIndex = 0;

StreamSubscription<Position>? _positionStream;

final LocationService _locationService = LocationService();

@override
void dispose() {
_positionStream?.cancel();
super.dispose();
}

Future<void> _toggleOnline(bool value) async {
final authService = Provider.of<AuthService>(
context,
listen: false,
);

if (authService.user == null) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('يجب تسجيل الدخول أولاً'),
),
);

return;
}

if (value) {
final hasPermission =
await _locationService.handleLocationPermission();

if (!hasPermission) {
if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text(
'يرجى تفعيل صلاحيات الموقع للبدء',
),
),
);

return;
}

if (!mounted) return;

setState(() {
isOnline = true;
});

await _positionStream?.cancel();

_positionStream = Geolocator.getPositionStream(
locationSettings: const LocationSettings(
accuracy: LocationAccuracy.high,
distanceFilter: 10,
),
).listen(
(Position position) async {
final user = authService.user;

if (user == null) return;

try {
await _locationService.updateDriverLocation(
user.uid,
position,
);
} catch (e) {
debugPrint(
'Driver location update error: $e',
);
}
},
onError: (error) {
debugPrint(
'Driver position stream error: $error',
);
},
);
} else {
await _positionStream?.cancel();
_positionStream = null;

if (!mounted) return;

setState(() {
isOnline = false;
});
}
}

void _onItemTapped(int index) {
if (index == 2) {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => const ProfileScreen(),
),
);

return;
}

setState(() {
_selectedIndex = index;
});
}

@override
Widget build(BuildContext context) {
final authService = Provider.of<AuthService>(context);

if (authService.user == null) {
return const Scaffold(
body: Center(
child: Text(
'يجب تسجيل الدخول أولاً',
),
),
);
}

final orderService = Provider.of<OrderService>(
context,
listen: false,
);

return Scaffold(
appBar: AppBar(
title: const Text('لوحة الكابتن'),
actions: [
Switch(
value: isOnline,
onChanged: _toggleOnline,
activeThumbColor: Colors.white,
activeTrackColor: AppTheme.primaryColor,
),
Padding(
padding: const EdgeInsets.symmetric(
horizontal: 8,
),
child: Center(
child: Text(
isOnline ? 'متصل' : 'غير متصل',
style: const TextStyle(
fontWeight: FontWeight.bold,
),
),
),
),
],
),
body: StreamBuilder<List<OrderModel>>(
stream: orderService.streamAvailableOrders(),
builder: (context, snapshot) {
if (snapshot.connectionState ==
ConnectionState.waiting) {
return const Center(
child: CircularProgressIndicator(),
);
}

if (snapshot.hasError) {
return Center(
child: Padding(
padding: const EdgeInsets.all(20),
child: Text(
'حدث خطأ أثناء تحميل الطلبات:\n${snapshot.error}',
textAlign: TextAlign.center,
),
),
);
}

final orders = snapshot.data ?? [];

return SingleChildScrollView(
padding: const EdgeInsets.all(16),
child: Column(
crossAxisAlignment:
CrossAxisAlignment.stretch,
children: [
Row(
children: [
Expanded(
child: _statCard(
title: 'الطلبات',
value: orders.length.toString(),
icon: Icons.shopping_bag,
color: Colors.blue,
),
),
const SizedBox(width: 16),
Expanded(
child: _statCard(
title: 'الأرباح',
value: '—',
icon:
Icons.account_balance_wallet,
color: Colors.green,
),
),
],
),

const SizedBox(height: 24),

const Text(
'طلبات قريبة منك',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
),
),

const SizedBox(height: 16),

if (orders.isEmpty)
Container(
padding: const EdgeInsets.all(30),
decoration: BoxDecoration(
color: Colors.grey.shade100,
borderRadius:
BorderRadius.circular(16),
),
child: const Column(
children: [
Icon(
Icons.inbox_outlined,
size: 50,
color: Colors.grey,
),
SizedBox(height: 12),
Text(
'لا توجد طلبات متاحة حالياً',
textAlign: TextAlign.center,
),
],
),
)
else
...orders.map(
(order) => _orderCard(
context,
order,
orderService,
),
),
],
),
);
},
),
bottomNavigationBar:
BottomNavigationBar(
currentIndex: _selectedIndex,
onTap: _onItemTapped,
selectedItemColor:
AppTheme.primaryColor,
unselectedItemColor: Colors.grey,
items: const [
BottomNavigationBarItem(
icon: Icon(Icons.dashboard),
label: 'الرئيسية',
),
BottomNavigationBarItem(
icon: Icon(Icons.history),
label: 'السجل',
),
BottomNavigationBarItem(
icon: Icon(Icons.person),
label: 'حسابي',
),
],
),
);
}

static Widget _statCard({
required String title,
required String value,
required IconData icon,
required Color color,
}) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.1),
borderRadius: BorderRadius.circular(16),
),
child: Column(
children: [
Icon(
icon,
color: color,
),
const SizedBox(height: 8),
Text(
title,
style: const TextStyle(
color: Colors.black54,
),
),
const SizedBox(height: 4),
Text(
value,
style: const TextStyle(
fontSize: 18,
fontWeight: FontWeight.bold,
),
),
],
),
);
}

Widget _orderCard(
BuildContext context,
OrderModel order,
OrderService orderService,
) {
return Card(
margin: const EdgeInsets.only(
bottom: 16,
),
shape: RoundedRectangleBorder(
borderRadius:
BorderRadius.circular(16),
),
child: Padding(
padding: const EdgeInsets.all(16),
child: Column(
children: [
Row(
children: [
Container(
padding:
const EdgeInsets.all(10),
decoration: BoxDecoration(
color: AppTheme.primaryColor
    .withValues(alpha: 0.1),
shape: BoxShape.circle,
),
child: const Icon(
Icons.restaurant,
color:
AppTheme.primaryColor,
),
),

const SizedBox(width: 12),

Expanded(
child: Column(
crossAxisAlignment:
CrossAxisAlignment.start,
children: [
Text(
order.restaurantName,
style:
const TextStyle(
fontWeight:
FontWeight.bold,
),
),
const SizedBox(height: 4),
Text(
'حجز لـ ${order.peopleCount} أشخاص',
style:
const TextStyle(
color: Colors.grey,
fontSize: 12,
),
),
],
),
),
],
),

const Divider(height: 24),

Row(
children: [
const Icon(
Icons.location_on,
size: 18,
color: Colors.red,
),
const SizedBox(width: 8),
Expanded(
child: Text(
order.pickupLocation ??
'موقع الاستلام غير محدد',
style:
const TextStyle(
fontSize: 13,
),
),
),
],
),

const SizedBox(height: 10),

Row(
children: [
const Icon(
Icons.flag,
size: 18,
color: Colors.green,
),
const SizedBox(width: 8),
Expanded(
child: Text(
order.returnLocation ??
'موقع العودة غير محدد',
style:
const TextStyle(
fontSize: 13,
),
),
),
],
),

const SizedBox(height: 16),

Container(
padding:
const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.green
    .withValues(alpha: 0.08),
borderRadius:
BorderRadius.circular(12),
),
child: Row(
mainAxisAlignment:
MainAxisAlignment
    .spaceBetween,
children: [
const Text(
'مستحق السائق',
style: TextStyle(
fontWeight:
FontWeight.bold,
),
),
Text(
'${order.driverNetAmount.toStringAsFixed(2)} د.أ',
style:
const TextStyle(
color: Colors.green,
fontWeight:
FontWeight.bold,
fontSize: 17,
),
),
],
),
),

const SizedBox(height: 16),

SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: isOnline
? () async {
try {
await orderService
    .updateOrderStatus(
order.id,
OrderStatus.accepted,
driverId:
Provider.of<
AuthService>(
context,
listen: false,
).user!.uid,
);

if (!context.mounted) {
return;
}

Navigator.push(
context,
MaterialPageRoute(
builder: (_) =>
OrderTrackingScreen(
order: order.copyWith(
status:
OrderStatus
    .accepted,
driverId:
Provider.of<
AuthService>(
context,
listen: false,
).user!.uid,
),
),
),
);
} catch (e) {
if (!context.mounted) {
return;
}

ScaffoldMessenger
    .of(context)
    .showSnackBar(
SnackBar(
content: Text(
'تعذر قبول الطلب:\n$e',
),
),
);
}
}
    : () {
ScaffoldMessenger
    .of(context)
    .showSnackBar(
const SnackBar(
content: Text(
'يجب تشغيل حالة "متصل" أولاً',
),
),
);
},
child: const Text(
'قبول الطلب',
),
),
),
],
),
),
);
}
}