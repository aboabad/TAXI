import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  restaurantAccepted,
  accepted,
  preparing,
  onTheWay,
  delivered,
  cancelled,
}

class OrderModel {
  final String id;
  final String userId;
  final String restaurantId;
  final String restaurantName;
  final String? driverId;
  final int peopleCount;
  final DateTime bookingDate;
  final int bookingDuration;
  final List<Map<String, dynamic>> items;
  final double restaurantPrice;
  final double outboundDistanceKm;
  final double returnDistanceKm;
  final double roundTripDeliveryPrice;
  final double discount;
  final String? pickupLocation;
  final String? returnLocation;
  final double foodTotal;
  final double subtotal;
  final double totalPrice;
  final double restaurantCommissionRate;
  final double restaurantCommission;
  final double restaurantNetAmount;
  final double driverCommissionRate;
  final double driverCommission;
  final double driverNetAmount;
  final double adminRevenue;
  final OrderStatus status;
  final DateTime createdAt;
  final String? note;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurantName,
    this.driverId,
    required this.peopleCount,
    required this.bookingDate,
    required this.bookingDuration,
    required this.items,
    required this.restaurantPrice,
    this.outboundDistanceKm = 0.0,
    this.returnDistanceKm = 0.0,
    required this.roundTripDeliveryPrice,
    required this.discount,
    this.pickupLocation,
    this.returnLocation,
    required this.foodTotal,
    required this.subtotal,
    required this.totalPrice,
    this.restaurantCommissionRate = 0.0,
    this.restaurantCommission = 0.0,
    this.restaurantNetAmount = 0.0,
    this.driverCommissionRate = 0.0,
    this.driverCommission = 0.0,
    this.driverNetAmount = 0.0,
    this.adminRevenue = 0.0,
    required this.status,
    required this.createdAt,
    this.note,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return OrderModel(
      id: doc.id,
      userId: data['userId']?.toString() ?? '',
      restaurantId: data['restaurantId']?.toString() ?? '',
      restaurantName: data['restaurantName']?.toString() ?? '',
      driverId: data['driverId']?.toString(),
      peopleCount: _toInt(data['peopleCount'], defaultValue: 1),
      bookingDate: _toDateTime(data['bookingDate']),
      bookingDuration: _toInt(data['bookingDuration'], defaultValue: 1),
      items: _parseItems(data['items']),
      restaurantPrice: _toDouble(data['restaurantPrice']),
      outboundDistanceKm: _toDouble(data['outboundDistanceKm']),
      returnDistanceKm: _toDouble(data['returnDistanceKm']),
      roundTripDeliveryPrice: _toDouble(data['roundTripDeliveryPrice']),
      discount: _toDouble(data['discount']),
      pickupLocation: data['pickupLocation']?.toString(),
      returnLocation: data['returnLocation']?.toString(),
      foodTotal: _toDouble(data['foodTotal']),
      subtotal: _toDouble(data['subtotal']),
      totalPrice: _toDouble(data['totalPrice']),
      restaurantCommissionRate: _toDouble(data['restaurantCommissionRate']),
      restaurantCommission: _toDouble(data['restaurantCommission']),
      restaurantNetAmount: _toDouble(data['restaurantNetAmount']),
      driverCommissionRate: _toDouble(data['driverCommissionRate']),
      driverCommission: _toDouble(data['driverCommission']),
      driverNetAmount: _toDouble(data['driverNetAmount']),
      adminRevenue: _toDouble(data['adminRevenue']),
      status: _statusFromString(data['status']),
      createdAt: _toDateTime(data['createdAt']),
      note: data['note']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'driverId': driverId,
      'peopleCount': peopleCount,
      'bookingDate': Timestamp.fromDate(bookingDate),
      'bookingDuration': bookingDuration,
      'items': items,
      'restaurantPrice': restaurantPrice,
      'outboundDistanceKm': outboundDistanceKm,
      'returnDistanceKm': returnDistanceKm,
      'roundTripDeliveryPrice': roundTripDeliveryPrice,
      'discount': discount,
      'pickupLocation': pickupLocation,
      'returnLocation': returnLocation,
      'foodTotal': foodTotal,
      'subtotal': subtotal,
      'totalPrice': totalPrice,
      'restaurantCommissionRate': restaurantCommissionRate,
      'restaurantCommission': restaurantCommission,
      'restaurantNetAmount': restaurantNetAmount,
      'driverCommissionRate': driverCommissionRate,
      'driverCommission': driverCommission,
      'driverNetAmount': driverNetAmount,
      'adminRevenue': adminRevenue,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'note': note,
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? restaurantId,
    String? restaurantName,
    String? driverId,
    int? peopleCount,
    DateTime? bookingDate,
    int? bookingDuration,
    List<Map<String, dynamic>>? items,
    double? restaurantPrice,
    double? outboundDistanceKm,
    double? returnDistanceKm,
    double? roundTripDeliveryPrice,
    double? discount,
    String? pickupLocation,
    String? returnLocation,
    double? foodTotal,
    double? subtotal,
    double? totalPrice,
    double? restaurantCommissionRate,
    double? restaurantCommission,
    double? restaurantNetAmount,
    double? driverCommissionRate,
    double? driverCommission,
    double? driverNetAmount,
    double? adminRevenue,
    OrderStatus? status,
    DateTime? createdAt,
    String? note,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
      driverId: driverId ?? this.driverId,
      peopleCount: peopleCount ?? this.peopleCount,
      bookingDate: bookingDate ?? this.bookingDate,
      bookingDuration: bookingDuration ?? this.bookingDuration,
      items: items ?? this.items,
      restaurantPrice: restaurantPrice ?? this.restaurantPrice,
      outboundDistanceKm: outboundDistanceKm ?? this.outboundDistanceKm,
      returnDistanceKm: returnDistanceKm ?? this.returnDistanceKm,
      roundTripDeliveryPrice:
          roundTripDeliveryPrice ?? this.roundTripDeliveryPrice,
      discount: discount ?? this.discount,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      returnLocation: returnLocation ?? this.returnLocation,
      foodTotal: foodTotal ?? this.foodTotal,
      subtotal: subtotal ?? this.subtotal,
      totalPrice: totalPrice ?? this.totalPrice,
      restaurantCommissionRate:
          restaurantCommissionRate ?? this.restaurantCommissionRate,
      restaurantCommission: restaurantCommission ?? this.restaurantCommission,
      restaurantNetAmount: restaurantNetAmount ?? this.restaurantNetAmount,
      driverCommissionRate: driverCommissionRate ?? this.driverCommissionRate,
      driverCommission: driverCommission ?? this.driverCommission,
      driverNetAmount: driverNetAmount ?? this.driverNetAmount,
      adminRevenue: adminRevenue ?? this.adminRevenue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static List<Map<String, dynamic>> _parseItems(dynamic value) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static OrderStatus _statusFromString(dynamic value) {
    switch (value?.toString()) {
      case 'restaurantAccepted':
        return OrderStatus.restaurantAccepted;
      case 'accepted':
        return OrderStatus.accepted;
      case 'preparing':
        return OrderStatus.preparing;
      case 'onTheWay':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }
}
