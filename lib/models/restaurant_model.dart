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
  final String ownerUid;
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

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.category,
    this.ownerUid = '',
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
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      ownerUid: map['ownerUid']?.toString() ?? '',
      ownerUsername: map['ownerUsername']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      rating: (map['rating'] as num? ?? 0).toDouble(),
      verified: map['verified'] == true,
      status: RestaurantStatus.values.firstWhere(
        (status) => status.name == map['status'],
        orElse: () => RestaurantStatus.pending,
      ),
      commissionRate: (map['commissionRate'] as num? ?? 0.10).toDouble(),
      tablesCount: (map['tablesCount'] as num? ?? 0).toInt(),
      availableTables: (map['availableTables'] as num? ?? 0).toInt(),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory RestaurantModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return RestaurantModel.fromMap(doc.data() ?? {}, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'ownerUid': ownerUid,
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
    String? ownerUid,
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
      ownerUid: ownerUid ?? this.ownerUid,
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
