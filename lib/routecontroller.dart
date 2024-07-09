// import 'package:geolocator/geolocator.dart';
// import 'package:get/get.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math';
// import 'dart:async';
//
// class RouteController extends GetxController {
//   var selectedLocations = <LatLng>[].obs;
//   var routeCoordinates = <LatLng>[].obs;
//   var totalDistance = 0.0.obs;
//   var isLoading = false.obs;
//   var errorMessage = RxnString();
//
//   Timer? _debounce;
//
//   LatLng? liveLocation;
//
//   LatLng startLocation = LatLng(10.5881, 77.2489); // Udumalaipet coordinates
//   Map<String, LatLng> _locationCache = {};
//   Map<String, List<LatLng>> _routeCache = {};
//
//   void addLocation(LatLng location) {
//     if (selectedLocations.length < 15) {
//       selectedLocations.add(location);
//     }
//   }
//
//   void removeLocation(int index) {
//     selectedLocations.removeAt(index);
//   }
//
//   void reorderLocations(int oldIndex, int newIndex) {
//     if (newIndex > oldIndex) {
//       newIndex -= 1;
//     }
//     final item = selectedLocations.removeAt(oldIndex);
//     selectedLocations.insert(newIndex, item);
//   }
//
//   Future<void> getRoute() async {
//     if (selectedLocations.isEmpty) return;
//
//     isLoading.value = true;
//     errorMessage.value = null;
//
//     String waypoints = selectedLocations
//         .map((location) => '${location.longitude},${location.latitude}')
//         .join(';');
//     String cacheKey = '${startLocation.longitude},${startLocation.latitude};$waypoints';
//
//     if (_routeCache.containsKey(cacheKey)) {
//       routeCoordinates.value = _routeCache[cacheKey]!;
//       _calculateTotalDistance();
//       isLoading.value = false;
//       return;
//     }
//
//     String url =
//         'https://router.project-osrm.org/route/v1/driving/${startLocation.longitude},${startLocation.latitude};$waypoints?overview=full&geometries=geojson';
//
//     try {
//       var response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 60));
//       var json = jsonDecode(response.body);
//
//       if (json['routes'] == null || json['routes'].isEmpty) {
//         errorMessage.value = 'No route found';
//         isLoading.value = false;
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
//       _routeCache[cacheKey] = routeCoordinates.toList();
//       _calculateTotalDistance();
//
//       isLoading.value = false;
//     } catch (e) {
//       errorMessage.value = 'Error fetching route: $e';
//       isLoading.value = false;
//     }
//   }
//
//   Future<LatLng?> getLatLngFromAddress(String address) async {
//     if (_locationCache.containsKey(address)) {
//       return _locationCache[address];
//     }
//
//     final url = 'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1';
//     final response = await http.get(Uri.parse(url));
//     final json = jsonDecode(response.body);
//
//     if (json.isNotEmpty) {
//       final lat = double.parse(json[0]['lat']);
//       final lon = double.parse(json[0]['lon']);
//       final location = LatLng(lat, lon);
//       _locationCache[address] = location;
//       return location;
//     }
//
//     return null;
//   }
//
//   void _calculateTotalDistance() {
//     totalDistance.value = 0.0;
//     for (int i = 0; i < routeCoordinates.length - 1; i++) {
//       totalDistance.value += _calculateDistance(routeCoordinates[i], routeCoordinates[i + 1]);
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
//
// // Inside RouteController class
//
//   void onSearchChanged(String query) {
//     if (_debounce?.isActive ?? false) _debounce?.cancel();
//     _debounce = Timer(Duration(milliseconds: 500), () {
//       _performSearch(query);
//     });
//   }
//
//   void _performSearch(String query) async {
//     LatLng? location = await getLatLngFromAddress(query);
//     if (location != null) {
//       selectedLocations.add(location);
//     }
//   }
//
//   void getLiveLocation() async {
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
//       return Future.error('Location permissions are permanently denied, we cannot request permissions.');
//     }
//
//     Geolocator.getPositionStream().listen((Position position) {
//       liveLocation = LatLng(position.latitude, position.longitude);
//       update(); // Notify GetX to rebuild the widgets
//     });
//   }
//
// }


