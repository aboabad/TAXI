import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi/core/app_theme.dart';

class SelectLocationScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const SelectLocationScreen({
    super.key,
    this.initialPosition,
  });

  @override
  State<SelectLocationScreen> createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLatLng = const LatLng(31.9539, 35.9106); // موقع افتراضي (عمان)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedLatLng = widget.initialPosition!;
      _isLoading = false;
    } else {
      _determineInitialPosition();
    }
  }

  // الحصول على الموقع الحالي للمستخدم عند فتح الخريطة لأول مرة
  Future<void> _determineInitialPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLatLng = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLatLng, 15),
      );
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حدد موقع الانطلاق على الخريطة'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // 1. الخريطة
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _selectedLatLng = position.target;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // 2. دبوس ثابت في منتصف الشاشة للتحريك
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 35),
              child: Icon(
                Icons.location_on,
                size: 45,
                color: AppTheme.primaryColor,
              ),
            ),
          ),

          // 3. زر العودة لموقعي الحالي
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location_btn',
              backgroundColor: Colors.white,
              onPressed: _determineInitialPosition,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          // 4. زر تأكيد الموقع المختار
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () {
                // إرجاع الإحداثيات المختارة عند العودة
                Navigator.of(context).pop(_selectedLatLng);
              },
              child: const Text(
                'تأكيد هذا الموقع',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}