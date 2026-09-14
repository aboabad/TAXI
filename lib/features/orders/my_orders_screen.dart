import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/core/auth_service.dart';
import 'package:taxi/features/orders/booking_invoice_screen.dart';
import 'package:taxi/models/order_model.dart';
import 'package:taxi/services/order_service.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final orderService = Provider.of<OrderService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('حجوزاتي وطلباتي'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('يرجى تسجيل الدخول لعرض الحجوزات'))
          : StreamBuilder<List<OrderModel>>(
              stream: orderService.streamUserOrders(user.uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'حدث خطأ أثناء تحميل الحجوزات:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data ?? [];
                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'لا توجد حجوزات',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) => OrderCard(
                    order: orders[index],
                  ),
                );
              },
            ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final OrderModel order;

  const OrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openInvoice(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      order.restaurantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '${order.peopleCount} أشخاص',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      intl.DateFormat('yyyy/MM/dd - hh:mm a', 'ar')
                          .format(order.bookingDate),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'إجمالي الفاتورة:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '${order.totalPrice.toStringAsFixed(2)} د.أ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openInvoice(context),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('عرض الفاتورة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openInvoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingInvoiceScreen(
          restaurantName: order.restaurantName,
          bookingId: order.id,
          peopleCount: order.peopleCount,
          bookingDate: order.bookingDate,
          status: _getStatusText(order.status),
          totalPrice: order.totalPrice,
        ),
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'بانتظار موافقة المطعم';
      case OrderStatus.restaurantAccepted:
        return 'المطعم وافق - بانتظار السائق';
      case OrderStatus.accepted:
        return 'تم تعيين سائق';
      case OrderStatus.preparing:
        return 'يتم التحضير';
      case OrderStatus.onTheWay:
        return 'في الطريق';
      case OrderStatus.delivered:
        return 'تم التوصيل';
      case OrderStatus.cancelled:
        return 'ملغي';
    }
  }
}

class StatusChip extends StatelessWidget {
  final OrderStatus status;

  const StatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final statusInfo = _getStatusInfo(status);
    final color = statusInfo.$1;
    final text = statusInfo.$2;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  (Color, String) _getStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return (Colors.orange, 'بانتظار المطعم');
      case OrderStatus.restaurantAccepted:
        return (Colors.lightBlue, 'بانتظار السائق');
      case OrderStatus.accepted:
        return (Colors.blue, 'تم تعيين سائق');
      case OrderStatus.preparing:
        return (Colors.purple, 'يتم التحضير');
      case OrderStatus.onTheWay:
        return (Colors.indigo, 'في الطريق');
      case OrderStatus.delivered:
        return (Colors.green, 'تم التوصيل');
      case OrderStatus.cancelled:
        return (Colors.red, 'ملغي');
    }
  }
}
