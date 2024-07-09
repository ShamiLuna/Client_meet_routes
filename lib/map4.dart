// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math';
// import 'package:geolocator/geolocator.dart';
//
// class MapsScreen extends StatefulWidget {
//   @override
//   _MapsScreenState createState() => _MapsScreenState();
// }
//
// class _MapsScreenState extends State<MapsScreen> {
//   List<LatLng> routeCoordinates = [];
//   double totalDistance = 0.0;
//   final LatLng startLocation = LatLng(10.5881, 77.2489); // Udumalaipet coordinates
//
//   List<LatLng> selectedLocations = [];
//   LatLng? liveLocation;
//   bool isLoading = false;
//   String? errorMessage;
//   final List<TextEditingController> _controllers = List.generate(15, (index) => TextEditingController());
//
//   @override
//   void initState() {
//     super.initState();
//     _getLiveLocation();
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
//         routeCoordinates.add(LatLng(coordinate[1], coordinate[0]));
//       }
//
//       _calculateTotalDistance();
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
//   void _resetSelection() {
//     selectedLocations.clear();
//     routeCoordinates.clear();
//     totalDistance = 0.0;
//     setState(() {});
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
//   @override
//   void dispose() {
//     for (var controller in _controllers) {
//       controller.dispose();
//     }
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
//                   _getRoute;
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
//                 zoom: 10.0,
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
//                       strokeWidth: 4.0,
//                       color: Colors.purple,
//                     ),
//                   ],
//                 ),
//                 MarkerLayer(
//                   markers: [
//                     for (var location in selectedLocations)
//                       Marker(
//                         width: 80.0,
//                         height: 80.0,
//                         point: location,
//                         builder: (ctx) => GestureDetector(
//                           onLongPress: () {
//                             int index = selectedLocations.indexOf(location);
//                             if (index != -1) {
//                               _removeWaypoint(index);
//                             }
//                           },
//                           onTap: () async {
//                             int index = selectedLocations.indexOf(location);
//                             if (index != -1) {
//                               // Show dialog to get new location
//                               LatLng? newLocation = await showDialog(
//                                 context: context,
//                                 builder: (context) {
//                                   TextEditingController _newLocationController = TextEditingController();
//                                   return AlertDialog(
//                                     title: Text('Edit Waypoint'),
//                                     content: TextField(
//                                       controller: _newLocationController,
//                                       decoration: InputDecoration(labelText: 'New Location'),
//                                     ),
//                                     actions: [
//                                       ElevatedButton(
//                                         onPressed: () {
//                                           Navigator.pop(context, null);
//                                         },
//                                         child: Text('Cancel'),
//                                       ),
//                                       ElevatedButton(
//                                         onPressed: () async {
//                                           LatLng? newLatLng = await _getLatLngFromAddress(_newLocationController.text);
//                                           Navigator.pop(context, newLatLng);
//                                         },
//                                         child: Text('Submit'),
//                                       ),
//                                     ],
//                                   );
//                                 },
//                               );
//
//                               if (newLocation != null) {
//                                 _editWaypoint(index, newLocation);
//                               }
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
//                       backgroundColor: Colors.yellow
//                   ),
//                   onPressed: _getRoute,
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
