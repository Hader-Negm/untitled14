// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'Admin.dart'; // تأكد من استيراد ملف الصفحة الأخرى
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Flutter App',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: Driver(),
//     );
//   }
// }
//
// class Driver extends StatefulWidget {
//   @override
//   _DriverState createState() => _DriverState();
// }
//
// class _DriverState extends State<Driver> {
//   static bool _isLocationServiceEnabled = false;
//   Position? _currentPosition;
//   StreamSubscription<Position>? _positionStreamSubscription;
//   final StreamController<Position?> _positionStreamController = StreamController<Position?>.broadcast();
//   bool _isTracking = false;
//   bool _isLoading = false;
//   bool _isPaused = false;
//   Color _buttonColor = Colors.blue;
//   Timer? _loadingTimer;
//   Timer? _trackingTimer;
//   Timer? _pauseTimer;
//   double _buttonScale = 1.0;
//   int _hours = 0;
//   int _minutes = 0;
//   int _seconds = 0;
//   int _pausedHours = 0;
//   int _pausedMinutes = 0;
//   int _pausedSeconds = 0;
//   DateTime? _pauseStartTime;
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkInitialState();
//     });
//   }
//
//   Future<void> _checkInitialState() async {
//     await _checkLocationServices();
//     await _loadTrackingState();
//   }
//
//   Future<void> _checkLocationServices() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     setState(() {
//       _isLocationServiceEnabled = serviceEnabled;
//     });
//
//     if (!_isLocationServiceEnabled) {
//       _showLocationServicesDialog(); // Show dialog if location services are disabled
//     }
//   }
//
//   void _showLocationServicesDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dismissal by tapping outside
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Location Services Disabled'),
//           content: Text('Please enable location services to use this feature.'),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 Navigator.of(context).pop(); // Close the dialog
//                 await Geolocator.openLocationSettings(); // Open location settings
//                 await _checkLocationServices(); // Retry checking location services
//               },
//               child: Text('OK'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog without action
//               },
//               child: Text('No, Thanks'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _loadTrackingState() async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     bool isTracking = prefs.getBool('isTracking') ?? false;
//
//     if (isTracking) {
//       Position? position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high,
//       );
//
//       setState(() {
//         _currentPosition = position;
//         _isTracking = true;
//       });
//     } else {
//       setState(() {
//         _currentPosition = null;
//         _isTracking = false;
//       });
//     }
//   }
//
//
//   Future<void> _startTracking() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       _showLocationServicesDialog();
//       return;
//     }
//
//     LocationPermission permission = await Geolocator.requestPermission();
//     if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
//       print('Location permissions are denied');
//       _showLocationServicesDialog();
//       return;
//     }
//
//     setState(() {
//       _isTracking = true;
//       _buttonColor = Colors.green;
//       _isLoading = false;
//       _isPaused = false; // Reset pause state when starting tracking
//     });
//
//     _positionStreamSubscription = Geolocator.getPositionStream(
//       locationSettings: LocationSettings(
//         accuracy: LocationAccuracy.high,
//       ),
//     ).listen((Position position) {
//       setState(() {
//         _currentPosition = position;
//       });
//       _saveTrackingState(true, position); // Save position data
//     });
//
//     _trackingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
//       if (!_isLoading && !_isPaused) {
//         setState(() {
//           _seconds++;
//           if (_seconds == 60) {
//             _seconds = 0;
//             _minutes++;
//             if (_minutes == 60) {
//               _minutes = 0;
//               _hours++;
//             }
//           }
//         });
//       }
//     });
//   }
//
//   Future<void> _stopTracking() async {
//     // Cancel position stream subscription
//     _positionStreamSubscription?.cancel();
//     // Cancel any active timers
//     _trackingTimer?.cancel();
//     _pauseTimer?.cancel();
//
//     // Reset state
//     setState(() {
//       _isTracking = false;
//       _buttonColor = Colors.grey;
//       _isLoading = false;
//       _isPaused = false;
//       _hours = 0;
//       _minutes = 0;
//       _seconds = 0;
//       _pausedHours = 0;
//       _pausedMinutes = 0;
//       _pausedSeconds = 0;
//     });
//
//     // Clear saved tracking data
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.remove('latitude'); // Remove saved latitude
//     await prefs.remove('longitude'); // Remove saved longitude
//     await prefs.setBool('isTracking', false); // Update tracking state
//   }
//
//   void _toggleTracking() async {
//     setState(() {
//       _isLoading = true;
//     });
//
//     _loadingTimer = Timer(Duration(seconds: 30), () {
//       if (_isLoading) {
//         setState(() {
//           _isLoading = false;
//         });
//         _showErrorDialog();
//       }
//     });
//
//     await Future.delayed(Duration(seconds: 2));
//
//     if (_isTracking) {
//       await _stopTracking();
//     } else {
//       await _startTracking();
//     }
//
//     _loadingTimer?.cancel(); // Cancel the timer if tracking started or stopped successfully
//     setState(() {
//       _isLoading = false;
//     });
//   }
//
//   void _pauseTracking() {
//     setState(() {
//       _isPaused = true;
//       _pauseStartTime = DateTime.now();
//       _pauseTimer = Timer.periodic(Duration(seconds: 1), (timer) {
//         if (_isPaused) {
//           setState(() {
//             final elapsed = DateTime.now().difference(_pauseStartTime!).inSeconds;
//             _pausedSeconds = elapsed % 60;
//             _pausedMinutes = (elapsed ~/ 60) % 60;
//             _pausedHours = (elapsed ~/ 3600);
//           });
//         }
//       });
//     });
//   }
//
//   void _resumeTracking() {
//     setState(() {
//       _isPaused = false;
//       _pauseTimer?.cancel();
//     });
//   }
//
//   void _showErrorDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false, // Prevent dismissal by tapping outside
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Error'),
//           content: Text('Please try again'),
//           actions: [
//             TextButton(
//               onPressed: _retry,
//               child: Text('Try Again'),
//             ),
//             TextButton(
//               onPressed: _ok,
//               child: Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _retry() {
//     Navigator.of(context).pop(); // Close the error dialog
//     _toggleTracking(); // Retry the tracking process
//   }
//
//   void _ok() async {
//     Navigator.of(context).pop(); // Close the dialog
//     await Geolocator.openLocationSettings(); // Open location settings
//   }
//
//   Future<void> _saveTrackingState(bool isTracking, Position position) async {
//     final SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('isTracking', isTracking);
//     if (isTracking) {
//       await prefs.setDouble('latitude', position.latitude);
//       await prefs.setDouble('longitude', position.longitude);
//     }
//   }
//
//   @override
//   void dispose() {
//     _positionStreamSubscription?.cancel();
//     _loadingTimer?.cancel();
//     _trackingTimer?.cancel();
//     _pauseTimer?.cancel();
//     _positionStreamController.close();
//     super.dispose();
//   }
//
//   void _onTapDown(TapDownDetails details) {
//     setState(() {
//       _buttonScale = 0.95; // Scale down the button when pressed
//     });
//   }
//
//   void _onTapUp(TapUpDetails details) {
//     setState(() {
//       _buttonScale = 1.0; // Scale up the button when released
//     });
//   }
//
//   Widget build(BuildContext context) {
//     String statusText = _isLoading ? 'Wait' : (_isTracking ? 'ON' : 'OFF');
//     Color textColor = _isLoading
//         ? Colors.red
//         : (_isTracking ? Colors.green : Colors.grey);
//
//     bool showPauseButton = _isTracking && !_isPaused;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Driver',
//           style: TextStyle(
//             fontSize: 23,
//             fontWeight: FontWeight.bold,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: Colors.black,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.admin_panel_settings),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => AdminPage(
//                     isTracking: _isTracking,
//                     currentPosition: _currentPosition,
//                     positionStream: _positionStreamController.stream,
//                   ),
//                 ),
//               );
//             },
//           ),
//           IconButton(
//             icon: Icon(Icons.map),
//             onPressed: () {
//               if (_currentPosition != null) {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => MapScreen(
//                       currentPosition: _currentPosition!,
//                       positionStream: _positionStreamController.stream,
//                       isTracking: _isTracking,
//                     ),
//                   ),
//                 );
//               } else {
//                 // Handle the case where currentPosition is null
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Current position is not available')),
//                 );
//               }
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               statusText,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 30,
//                 fontWeight: FontWeight.bold,
//                 color: textColor,
//               ),
//             ),
//             const SizedBox(height: 20),
//             GestureDetector(
//               onTap: _toggleTracking,
//               onTapDown: _onTapDown,
//               onTapUp: _onTapUp,
//               child: AnimatedContainer(
//                 duration: Duration(milliseconds: 200),
//                 transform: Matrix4.identity()..scale(_buttonScale),
//                 width: 170,
//                 height: 170,
//                 decoration: BoxDecoration(
//                   color: _isLoading ? Colors.red : _buttonColor,
//                   shape: BoxShape.circle,
//                 ),
//                 child: Center(
//                   child: _isLoading
//                       ? CircularProgressIndicator(
//                     strokeWidth: 8.0,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   )
//                       : Icon(
//                     _isTracking ? Icons.stop : Icons.power_settings_new,
//                     color: Colors.white,
//                     size: 80,
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(height: 20),
//             // Main Timer
//             Text(
//               "${_isTracking || _isLoading ? _hours.toString().padLeft(2, '0') : '00'}:${_isTracking || _isLoading ? _minutes.toString().padLeft(2, '0') : '00'}:${_isTracking || _isLoading ? _seconds.toString().padLeft(2, '0') : '00'}",
//               style: TextStyle(
//                 fontSize: 40,
//                 fontWeight: FontWeight.bold,
//                 color: _isLoading ? Colors.red : (textColor == Colors.green ? textColor : Colors.grey),
//               ),
//             ),
//             const SizedBox(height: 20),
//             // Pause Button and Timer
//             if (showPauseButton)
//               Column(
//                 children: [
//                   ElevatedButton(
//                     onPressed: _pauseTracking,
//                     child: Text('Pause'),
//                   ),
//                   if (_isPaused)
//                     Column(
//                       children: [
//                         Text(
//                           "${_pausedHours.toString().padLeft(2, '0')}:${_pausedMinutes.toString().padLeft(2, '0')}:${_pausedSeconds.toString().padLeft(2, '0')}",
//                           style: TextStyle(
//                             fontSize: 30,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey,
//                           ),
//                         ),
//                         const SizedBox(height: 10),
//                         Text(
//                           "Paused Timer",
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                 ],
//               ),
//             if (_isPaused)
//               Column(
//                 children: [
//                   ElevatedButton(
//                     onPressed: _resumeTracking,
//                     child: Text('Resume'),
//                   ),
//                   const SizedBox(height: 20),
//                   // Timer for Paused State
//                   Text(
//                     "${_pausedHours.toString().padLeft(2, '0')} : ${_pausedMinutes.toString().padLeft(2, '0')} : ${_pausedSeconds.toString().padLeft(2, '0')}",
//                     style: TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class MapScreen extends StatefulWidget {
//   final Position currentPosition;
//   final Stream<Position?> positionStream;
//   final bool isTracking;
//
//   MapScreen({
//     required this.currentPosition,
//     required this.positionStream,
//     required this.isTracking,
//   });
//
//   @override
//   _MapScreenState createState() => _MapScreenState();
// }
//
// class _MapScreenState extends State<MapScreen> {
//   late GoogleMapController _controller;
//   List _polylinePoints = [];
//   final String googleApiKey = 'YOUR_GOOGLE_API_KEY_HERE'; // أدخل مفتاح API الخاص بك هنا
//
//   @override
//   void initState() {
//     super.initState();
//     _setPolyline();
//   }
//
//   void _setPolyline() async {
//     // تأكد من إعداد PolylinePoints بشكل صحيح، وادخل قيمة مفتاح API
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Map Screen'),
//       ),
//       body:FlutterMap(
//         options:const MapOptions(
//           // initialCenter: LatLng(51.509364, -0.128928),
//           initialZoom: 9.2,
//         ),
//         children: [
//           TileLayer(
//             urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//             userAgentPackageName: 'com.example.app',
//           ),
//           RichAttributionWidget(
//             attributions: [
//               TextSourceAttribution(
//                 'OpenStreetMap contributors',
//                 onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')),
//               ),
//             ],
//           ),
//         ],
//       )
//       // GoogleMap(
//       //   initialCameraPosition: CameraPosition(
//       //     target: LatLng(widget.currentPosition.latitude, widget.currentPosition.longitude),
//       //     zoom: 14,
//       //   ),
//       //   onMapCreated: (controller) {
//       //     _controller = controller;
//       //   },
//       //   polylines: {
//       //     Polyline(
//       //       polylineId: PolylineId('route'),
//       //       points: _polylinePoints,
//       //       color: Colors.blue,
//       //       width: 5,
//       //     ),
//       //   },
//       //   markers: {
//       //     Marker(
//       //       markerId: MarkerId('currentLocation'),
//       //       position: LatLng(widget.currentPosition.latitude, widget.currentPosition.longitude),
//       //     ),
//       //   },
//       // ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:untitled14/screens/homepage.dart';
import 'package:untitled14/screens/ownerpage.dart';

void main ()
{
  runApp(myapp());
}

class myapp extends StatelessWidget {
  const myapp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}


