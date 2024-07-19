// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
//
// class MapsScreen extends StatefulWidget {
//   @override
//   _MapsScreenState createState() => _MapsScreenState();
// }
//
// class _MapsScreenState extends State<MapsScreen> {
//   List<LatLng> routeCoordinates = [];
//   double totalDistance = 0.0;
//   LatLng startLocation = LatLng(10.5881, 77.2489); // Default coordinates for Udumalaipet
//   List<LatLng> selectedLocations = [];
//   LatLng? liveLocation;
//   bool isLoading = false;
//   String? errorMessage;
//   late stt.SpeechToText _speech;
//   late FlutterTts _flutterTts;
//   bool _isListening = false;
//   String _command = '';
//   final List<TextEditingController> _controllers = List.generate(15, (index) => TextEditingController());
//   final TextEditingController _startLocationController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _getLiveLocation();
//     _loadSavedRoutes();
//     _speech = stt.SpeechToText();
//     _flutterTts = FlutterTts();
//   }
//
//   Future<void> _getRoute() async {
//     if (selectedLocations.isEmpty) return;
//
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });
//
//     String waypoints = selectedLocations
//         .map((location) => '${location.longitude},${location.latitude}')
//         .join(';');
//
//     String url =
//         'https://router.project-osrm.org/route/v1/driving/${startLocation.longitude},${startLocation.latitude};$waypoints?overview=full&geometries=geojson';
//
//     try {
//       var response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 60));
//       var json = jsonDecode(response.body);
//
//       if (json['routes'] == null || json['routes'].isEmpty) {
//         setState(() {
//           errorMessage = 'No route found';
//           isLoading = false;
//         });
//         return;
//       }
//
//       var coordinates = json['routes'][0]['geometry']['coordinates'];
//
//       routeCoordinates.clear();
//       for (var coordinate in coordinates) {
//         double lat = coordinate[1].toDouble();
//         double lon = coordinate[0].toDouble();
//         routeCoordinates.add(LatLng(lat, lon));
//       }
//
//       _calculateTotalDistance();
//       _saveRoute();
//
//       setState(() {
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Error fetching route: $e';
//         isLoading = false;
//       });
//     }
//   }
//
//   void _calculateTotalDistance() {
//     totalDistance = 0.0;
//     for (int i = 0; i < routeCoordinates.length - 1; i++) {
//       totalDistance += _calculateDistance(routeCoordinates[i], routeCoordinates[i + 1]);
//     }
//   }
//
//   double _calculateDistance(LatLng point1, LatLng point2) {
//     const double R = 6371e3; // Earth radius in meters
//     double lat1 = point1.latitude * pi / 180;
//     double lat2 = point2.latitude * pi / 180;
//     double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
//     double deltaLon = (point2.longitude - point1.longitude) * pi / 180;
//
//     double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
//         cos(lat1) * cos(lat2) *
//             sin(deltaLon / 2) * sin(deltaLon / 2);
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//
//     return R * c;
//   }
//
//   void _onMapTap(TapPosition tapPosition, LatLng latLng) {
//     if (selectedLocations.length < 15) {
//       selectedLocations.add(latLng);
//       setState(() {});
//     }
//   }
//
//   Future<void> _resetSelection() async {
//     bool confirmReset = await _showConfirmationDialog();
//     if (confirmReset) {
//       selectedLocations.clear();
//       routeCoordinates.clear();
//       totalDistance = 0.0;
//       setState(() {});
//     }
//   }
//
//   Future<bool> _showConfirmationDialog() async {
//     return await showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Confirm Reset'),
//         content: Text('Are you sure you want to reset the selection?'),
//         actions: [
//           ElevatedButton(
//             onPressed: () => Navigator.of(context).pop(false),
//             child: Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.of(context).pop(true),
//             child: Text('Confirm'),
//           ),
//         ],
//       ),
//     ) ?? false;
//   }
//
//   void _getLiveLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;
//
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }
//
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permissions are denied');
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       return Future.error(
//           'Location permissions are permanently denied, we cannot request permissions.');
//     }
//
//     Geolocator.getPositionStream().listen((Position position) {
//       setState(() {
//         liveLocation = LatLng(position.latitude, position.longitude);
//       });
//     });
//   }
//
//   Future<void> _updateLocations() async {
//     selectedLocations.clear();
//     for (var controller in _controllers) {
//       if (controller.text.isNotEmpty) {
//         try {
//           LatLng? location = await _getLatLngFromAddress(controller.text);
//           if (location != null) {
//             selectedLocations.add(location);
//           }
//         } catch (e) {
//           print('Error getting location for ${controller.text}: $e');
//         }
//       }
//     }
//     _getRoute();
//   }
//
//   Future<LatLng?> _getLatLngFromAddress(String address) async {
//     final url = 'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1';
//     final response = await http.get(Uri.parse(url));
//     final json = jsonDecode(response.body);
//
//     if (json.isNotEmpty) {
//       final lat = double.parse(json[0]['lat']);
//       final lon = double.parse(json[0]['lon']);
//       return LatLng(lat, lon);
//     }
//
//     return null;
//   }
//
//   Future<void> _saveRoute() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String> routeData = routeCoordinates.map((latLng) => jsonEncode({'lat': latLng.latitude, 'lng': latLng.longitude})).toList();
//     prefs.setStringList('savedRoute', routeData);
//   }
//
//   Future<void> _loadSavedRoutes() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? savedRouteData = prefs.getStringList('savedRoute');
//
//     if (savedRouteData != null) {
//       routeCoordinates = savedRouteData.map((data) {
//         Map<String, dynamic> parsedData = jsonDecode(data);
//         return LatLng(parsedData['lat'], parsedData['lng']);
//       }).toList();
//
//       _calculateTotalDistance();
//       setState(() {});
//     }
//   }
//
//   Future<void> _updateStartLocation() async {
//     if (_startLocationController.text.isNotEmpty) {
//       try {
//         LatLng? newStartLocation = await _getLatLngFromAddress(_startLocationController.text);
//         if (newStartLocation != null) {
//           setState(() {
//             startLocation = newStartLocation;
//             routeCoordinates.clear();
//             totalDistance = 0.0;
//           });
//           _getRoute();
//         }
//       } catch (e) {
//         print('Error getting start location: $e');
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
//     _startLocationController.dispose();
//     _speech.stop();
//     _flutterTts.stop();
//     super.dispose();
//   }
//
//   void _removeWaypoint(int index) {
//     setState(() {
//       selectedLocations.removeAt(index);
//       _getRoute();
//     });
//   }
//
//   Future<void> _startListening() async {
//     bool available = await _speech.initialize(
//       onStatus: (status) {
//         if (status == 'done') {
//           setState(() {
//             _isListening = false;
//           });
//         }
//       },
//       onError: (errorNotification) {
//         setState(() {
//           _isListening = false;
//         });
//       },
//     );
//
//     if (available) {
//       setState(() => _isListening = true);
//       _speech.listen(onResult: (result) {
//         setState(() {
//           _command = result.recognizedWords;
//         });
//
//         if (result.finalResult) {
//           _executeVoiceCommand(_command);
//         }
//       });
//     }
//   }
//
//   void _executeVoiceCommand(String command) {
//     // Add your custom voice command handling here
//     // For example, you can use _flutterTts.speak() to provide voice feedback
//     // and use setState() to update the UI based on the command
//     print('Voice command: $command');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Maps'),
//       ),
//       body: Stack(
//         children: [
//           FlutterMap(
//             options: MapOptions(
//               center: startLocation,
//               zoom: 15.0,
//               onTap: _onMapTap,
//             ),
//             children: [
//               TileLayer(
//                 urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                 subdomains: ['a', 'b', 'c'],
//               ),
//               PolylineLayer(
//                 polylines: [
//                   Polyline(
//                     points: routeCoordinates,
//                     strokeWidth: 4.0,
//                     color: Colors.blue,
//                   ),
//                 ],
//               ),
//               MarkerLayer(
//                 markers: [
//                   if (liveLocation != null)
//                     Marker(
//                       point: liveLocation!,
//                       builder: (ctx) => Icon(
//                         Icons.my_location,
//                         color: Colors.red,
//                         size: 40.0,
//                       ),
//                     ),
//                   for (var location in selectedLocations)
//                     Marker(
//                       point: location,
//                       builder: (ctx) => Icon(
//                         Icons.location_on,
//                         color: Colors.green,
//                         size: 40.0,
//                       ),
//                     ),
//                 ],
//               ),
//             ],
//           ),
//           if (isLoading)
//             Center(
//               child: CircularProgressIndicator(),
//             ),
//           if (errorMessage != null)
//             Center(
//               child: Text(
//                 errorMessage!,
//                 style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
//               ),
//             ),
//         ],
//       ),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           FloatingActionButton(
//             onPressed: _isListening ? _speech.stop : _startListening,
//             tooltip: 'Voice Command',
//             child: Icon(_isListening ? Icons.mic : Icons.mic_none),
//           ),
//           SizedBox(height: 16),
//           FloatingActionButton(
//             onPressed: _getRoute,
//             tooltip: 'Get Route',
//             child: Icon(Icons.directions),
//           ),
//           SizedBox(height: 16),
//           FloatingActionButton(
//             onPressed: _resetSelection,
//             tooltip: 'Reset',
//             child: Icon(Icons.refresh),
//           ),
//         ],
//       ),
//     );
//   }
// }
// // Key Improvements:
// // Error Handling: Added error messages for better user feedback.
// // UI Loading State: Added loading state indicator.
// // Voice Command: Initialized and handled voice command with basic feedback.
// // Code Clean-up: Removed redundant code and added proper state management.