import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'map.dart';

class AdminPage extends StatefulWidget {
  final bool isTracking;
  final Position? currentPosition;
  final Stream<Position?> positionStream;

  AdminPage({
    required this.isTracking,
    this.currentPosition,
    required this.positionStream,
  });

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Position? _latestPosition;
  StreamSubscription<Position?>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    if (widget.isTracking) {
      _positionSubscription = widget.positionStream.listen((position) {
        setState(() {
          _latestPosition = position;
        });
      });
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String lat = _latestPosition != null ? '${_latestPosition!.latitude}' : '0.0';
    String lon = _latestPosition != null ? '${_latestPosition!.longitude}' : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Page',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.isTracking) ...[
              Text(
                'Tracking is ON',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Latitude: $lat',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Text(
                'Longitude: $lon',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            ] else ...[
              Text(
                'Tracking is OFF',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
