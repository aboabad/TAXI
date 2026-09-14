import 'package:cloud_firestore/cloud_firestore.dart';

enum RestaurantStatus {
  active,
  pending,
  suspended,
  blocked,
}

class RestaurantModel {
  final String id;
  final String name;
  final String category;
  final String ownerUsername;
  final String address;
  final String description;
  final String imageUrl;
  final double rating;
  final bool verified;
  final RestaurantStatus status;
  final double commissionRate;
  final int tablesCount;
  final int availableTables;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.category,
    this.ownerUsername = '',
    this.address = '',
    this.description = '',
    this.imageUrl = '',
    required this.rating,
    required this.verified,
    required this.status,
    required this.commissionRate,
    required this.tablesCount,
    required this.availableTables,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory RestaurantModel.fromMap(Map<String, dynamic> map, String id) {
    return RestaurantModel(
      id: id,
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      ownerUsername: map['ownerUsername'] ?? '',
      address: map['address'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      verified: map['verified'] ?? false,
      status: RestaurantStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => RestaurantStatus.pending,
      ),
      commissionRate: (map['commissionRate'] ?? 0.1).toDouble(),
      tablesCount: map['tablesCount'] ?? 0,
      availableTables: map['availableTables'] ?? 0,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory RestaurantModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RestaurantModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'ownerUsername': ownerUsername,
      'address': address,
      'description': description,
      'imageUrl': imageUrl,
      'rating': rating,
      'verified': verified,
      'status': status.name,
      'commissionRate': commissionRate,
      'tablesCount': tablesCount,
      'availableTables': availableTables,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RestaurantModel copyWith({
    String? id,
    String? name,
    String? category,
    String? ownerUsername,
    String? address,
    String? description,
    String? imageUrl,
    double? rating,
    bool? verified,
    RestaurantStatus? status,
    double? commissionRate,
    int? tablesCount,
    int? availableTables,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      ownerUsername: ownerUsername ?? this.ownerUsername,
      address: address ?? this.address,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      verified: verified ?? this.verified,
      status: status ?? this.status,
      commissionRate: commissionRate ?? this.commissionRate,
      tablesCount: tablesCount ?? this.tablesCount,
      availableTables: availableTables ?? this.availableTables,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}