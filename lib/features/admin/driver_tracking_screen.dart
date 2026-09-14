import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi/core/app_theme.dart';
import 'package:taxi/services/location_service.dart';

class DriverTrackingScreen extends StatefulWidget {
  const DriverTrackingScreen({super.key});

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen> {
  final LocationService _locationService = LocationService();
  final Set<Marker> _markers = {};

  static const CameraPosition _initialView = CameraPosition(
    target: LatLng(31.9454, 35.9284),
    zoom: 12,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('متابعة السواقين'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Real Google Map
          GoogleMap(
            initialCameraPosition: _initialView,
            markers: _markers,
            onMapCreated: (controller) {},
          ),
          // Drivers List Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('السائقين المتاحين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('12 متصل الآن', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: StreamBuilder(
                      stream: _locationService.streamAllDrivers(),
                      builder: (context, snapshot) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const CircleAvatar(
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-1.2.1&auto=format&fit=crop&w=200&q=60'),
                              ),
                              title: Text('سائق ${index + 1}'),
                              subtitle: Text(index % 2 == 0 ? 'في رحلة توصيل' : 'متاح للعمل'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.my_location, color: AppTheme.primaryColor),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.call, color: Colors.green),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
