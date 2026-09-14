import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taxi/models/restaurant_model.dart';

class RestaurantService {
final FirebaseFirestore _db = FirebaseFirestore.instance;

CollectionReference<Map<String, dynamic>> get _restaurantsRef =>
_db.collection('restaurants');

/// جلب جميع المطاعم بشكل مباشر.
Stream<List<RestaurantModel>> streamRestaurants() {
return _restaurantsRef
    .orderBy('createdAt', descending: true)
    .snapshots()
    .map(
(snapshot) => snapshot.docs
    .map(RestaurantModel.fromFirestore)
    .toList(),
);
}

/// جلب مطعم واحد.
Future<RestaurantModel?> getRestaurant(String restaurantId) async {
final doc = await _restaurantsRef.doc(restaurantId).get();

if (!doc.exists) {
return null;
}

return RestaurantModel.fromFirestore(doc);
}

/// إضافة مطعم جديد.
Future<String> createRestaurant(RestaurantModel restaurant) async {
final doc = await _restaurantsRef.add(restaurant.toMap());
return doc.id;
}

/// تعديل بيانات المطعم.
Future<void> updateRestaurant(
String restaurantId,
Map<String, dynamic> data,
) async {
await _restaurantsRef.doc(restaurantId).update(data);
}

/// تغيير حالة المطعم.
Future<void> updateRestaurantStatus(
String restaurantId,
RestaurantStatus status,
) async {
await _restaurantsRef.doc(restaurantId).update({
'status': status.name,
});
}

/// الموافقة على المطعم.
Future<void> approveRestaurant(String restaurantId) async {
await _restaurantsRef.doc(restaurantId).update({
'verified': true,
'status': RestaurantStatus.active.name,
});
}

/// إيقاف المطعم مؤقتاً.
Future<void> suspendRestaurant(String restaurantId) async {
await updateRestaurantStatus(
restaurantId,
RestaurantStatus.suspended,
);
}

/// حظر المطعم.
Future<void> blockRestaurant(String restaurantId) async {
await updateRestaurantStatus(
restaurantId,
RestaurantStatus.blocked,
);
}

/// إعادة تفعيل المطعم.
Future<void> activateRestaurant(String restaurantId) async {
await updateRestaurantStatus(
restaurantId,
RestaurantStatus.active,
);
}

/// حذف المطعم.
Future<void> deleteRestaurant(String restaurantId) async {
await _restaurantsRef.doc(restaurantId).delete();
}

/// تحديث عدد الطاولات.
Future<void> updateTables({
required String restaurantId,
required int tablesCount,
required int availableTables,
}) async {
await _restaurantsRef.doc(restaurantId).update({
'tablesCount': tablesCount,
'availableTables': availableTables,
});
}

/// تحديث نسبة العمولة الخاصة بالمطعم.
///
/// مثال:
/// 0.10 = 10%
/// 0.15 = 15%
Future<void> updateCommissionRate({
required String restaurantId,
required double commissionRate,
}) async {
await _restaurantsRef.doc(restaurantId).update({
'commissionRate': commissionRate,
});
}
}