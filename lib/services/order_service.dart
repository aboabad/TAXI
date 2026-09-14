import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi/models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new order/booking
  Future<String> createOrder(OrderModel order) async {
    final docRef = await _db.collection('orders').add(order.toMap());
    return docRef.id;
  }

  // Stream of orders for a specific user
  Stream<List<OrderModel>> streamUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList(),
    );
  }

  // Stream of available orders for drivers
  Stream<List<OrderModel>> streamAvailableOrders() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList(),
    );
  }

  // Update order status
  Future<void> updateOrderStatus(
      String orderId,
      OrderStatus status, {
        String? driverId,
      }) async {
    final Map<String, dynamic> data = {
      'status': status.toString().split('.').last,
    };

    if (driverId != null) {
      data['driverId'] = driverId;
    }

    await _db.collection('orders').doc(orderId).update(data);
  }
}