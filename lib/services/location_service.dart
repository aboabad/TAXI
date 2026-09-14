import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Request location permission
  Future<bool> handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  // Update Driver Location in Firestore
  Future<void> updateDriverLocation(String driverId, Position position) async {
    await _db.collection('driver_locations').doc(driverId).set({
      'latitude': position.latitude,
      'longitude': position.longitude,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Stream of a specific driver's location
  Stream<DocumentSnapshot> streamDriverLocation(String driverId) {
    return _db.collection('driver_locations').doc(driverId).snapshots();
  }

  // Stream of all active drivers (for Admin)
  Stream<QuerySnapshot> streamAllDrivers() {
    return _db.collection('driver_locations').snapshots();
  }
}
