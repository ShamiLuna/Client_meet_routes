// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
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
//   final List<TextEditingController> _controllers = List.generate(15, (index) => TextEditingController());
//   final TextEditingController _startLocationController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _getLiveLocation();
//     _loadSavedRoutes();
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
//         // Ensure coordinates are parsed as doubles
//         double lat = coordinate[1].toDouble();
//         double lon = coordinate[0].toDouble();
//         routeCoordinates.add(LatLng(lat, lon));
//       }
//
//       _calculateTotalDistance();
//       _saveRoute(); // Save the route after calculating
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
//             startLocation = newStartLocation!;
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
//   void _editWaypoint(int index, LatLng newLocation) {
//     setState(() {
//       selectedLocations[index] = newLocation;
//       _getRoute();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Client Meeting Route'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.refresh),
//             onPressed: _resetSelection,
//           ),
//         ],
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: [
//             DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.blue,
//               ),
//               child: Text(
//                 'Enter Locations',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: TextField(
//                 controller: _startLocationController,
//                 decoration: InputDecoration(
//                   labelText: 'Start Location (address)',
//                 ),
//               ),
//             ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: ElevatedButton(
//                 onPressed: () {
//                   _updateStartLocation();
//                   Navigator.pop(context); // close the drawer
//                 },
//                 child: Text('Set Start Location'),
//               ),
//             ),
//             for (int i = 0; i < _controllers.length; i++)
//               Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: TextField(
//                   controller: _controllers[i],
//                   decoration: InputDecoration(
//                     labelText: 'Location ${i + 1} (address)',
//                   ),
//                 ),
//               ),
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context); // close the drawer
//                   _updateLocations();
//                 },
//                 child: Text('Submit'),
//               ),
//             ),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           if (isLoading)
//             LinearProgressIndicator(),
//           if (errorMessage != null)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Text(
//                 errorMessage!,
//                 style: TextStyle(color: Colors.red),
//               ),
//             ),
//           Expanded(
//             child: FlutterMap(
//               options: MapOptions(
//                 center: startLocation,
//                 zoom: 13.0,
//                 onTap: _onMapTap,
//               ),
//               children: [
//                 TileLayer(
//                   urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
//                   subdomains: ['a', 'b', 'c'],
//                 ),
//                 PolylineLayer(
//                   polylines: [
//                     Polyline(
//                       points: routeCoordinates,
//                       color: Colors.blue,
//                       strokeWidth: 4.0,
//                     ),
//                   ],
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     for (int i = 0; i < selectedLocations.length; i++)
//                       Marker(
//                         width: 80.0,
//                         height: 80.0,
//                         point: selectedLocations[i],
//                         builder: (ctx) => GestureDetector(
//                           onTap: () async {
//                             LatLng? newLocation = await showDialog(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 title: Text('Edit Location'),
//                                 content: TextFormField(
//                                   controller: _controllers[i],
//                                   decoration: InputDecoration(labelText: 'New Location'),
//                                 ),
//                                 actions: [
//                                   ElevatedButton(
//                                     onPressed: () {
//                                       Navigator.pop(context, null);
//                                     },
//                                     child: Text('Cancel'),
//                                   ),
//                                   ElevatedButton(
//                                     onPressed: () async {
//                                       LatLng? newLatLng = await _getLatLngFromAddress(_controllers[i].text);
//                                       Navigator.pop(context, newLatLng);
//                                       _getLiveLocation();
//                                     },
//                                     child: Text('Submit'),
//                                   ),
//                                 ],
//                               ),
//                             );
//
//                             if (newLocation != null) {
//                               _editWaypoint(i, newLocation);
//                             }
//                           },
//                           child: Container(
//                             child: Icon(
//                               Icons.location_on,
//                               color: Colors.green,
//                               size: 40.0,
//                             ),
//                           ),
//                         ),
//                       ),
//                     if (liveLocation != null)
//                       Marker(
//                         width: 80.0,
//                         height: 80.0,
//                         point: liveLocation!,
//                         builder: (ctx) => Container(
//                           child: Icon(
//                             Icons.circle,
//                             color: Colors.green,
//                             size: 40.0,
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Column(
//               children: [
//                 Text(
//                   'Total Distance: ${(totalDistance / 1000).toStringAsFixed(2)} km',
//                   style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 10),
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.yellow,
//                   ),
//                   onPressed: (){
//                     _getRoute();
//                     _getLiveLocation();
//
//                     ;},
//
//                   child: Text('Calculate Distance'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
//
// //All routes in driving mode,reset confirmation,green map symbol which is selected location editable ,starting location.
