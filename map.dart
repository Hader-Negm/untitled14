import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  late StreamSubscription<Position>? _positionStream;


  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startLocationUpdates();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
      _updateMarkerAndCircle(position);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    });
  }

  void _startLocationUpdates() {
    // تأكد من إلغاء الاشتراك السابق إذا كان موجوداً
    _positionStream?.cancel();

    // ابدأ الاستماع لتحديثات الموقع
    _positionStream = Geolocator.getPositionStream().listen(
          (Position position) {
        // تحديث الحالة والخرائط عند تلقي موقع جديد
        setState(() {
          _currentPosition = position;
          _updateMarkerAndCircle(position);
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(position.latitude, position.longitude),
            ),
          );
        });
      },
      onError: (error) {
        // تعامل مع الأخطاء إذا حدثت
        print("Error getting location updates: $error");
      },
    );
  }


  void _updateMarkerAndCircle(Position position) {
    final LatLng latLng = LatLng(position.latitude, position.longitude);

    _markers.add(
      Marker(
        markerId: MarkerId('currentLocation'),
        position: latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    _circles.add(
      Circle(
        circleId: CircleId('currentLocationCircle'),
        center: latLng,
        radius: 50, // Adjust the radius as needed
        fillColor: Colors.blue.withOpacity(0.2),
        strokeColor: Colors.blue,
        strokeWidth: 1,
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // تأكد من إلغاء الاشتراك
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Maps in Flutter')),
      body: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        initialCameraPosition:const CameraPosition(
          target: LatLng(37.7749, -122.4194), // San Francisco coordinates
          zoom: 12,
        ),
        markers: _markers,
        circles: _circles,
      ),
    );
  }
}
