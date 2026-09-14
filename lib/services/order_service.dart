import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi/models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createOrder(OrderModel order) async {
    final docRef = await _db.collection('orders').add(order.toMap());
    return docRef.id;
  }

  Stream<List<OrderModel>> streamUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<OrderModel>> streamRestaurantOrders(String restaurantId) {
    return _db
        .collection('orders')
        .where('restaurantId', isEqualTo: restaurantId)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Stream<List<OrderModel>> streamAvailableOrders() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: OrderStatus.restaurantAccepted.name)
        .snapshots()
        .map((snapshot) {
      final orders = snapshot.docs.map(OrderModel.fromFirestore).toList();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return orders;
    });
  }

  Future<void> updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? driverId,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (driverId != null) {
      data['driverId'] = driverId;
    }

    await _db.collection('orders').doc(orderId).update(data);
  }
}
