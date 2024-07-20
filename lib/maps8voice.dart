import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart'as stt;

class MapsScreen extends StatefulWidget {
  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  List<LatLng> routeCoordinates = [];
  double totalDistance = 0.0;
  LatLng startLocation = LatLng(10.5881, 77.2489); // Default coordinates for Udumalaipet
  List<LatLng> selectedLocations = [];
  LatLng? liveLocation;
  bool isLoading = false;
  String? errorMessage;
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _command = '';
  final List<TextEditingController> _controllers = List.generate(15, (index) => TextEditingController());
  final TextEditingController _startLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getLiveLocation();
    _loadSavedRoutes();
    // Initialize speech recognition and text-to-speech
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
  }




  Future<void> _getRoute() async {
    if (selectedLocations.isEmpty) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    String waypoints = selectedLocations
        .map((location) => '${location.longitude},${location.latitude}')
        .join(';');

    String url =
        'https://router.project-osrm.org/route/v1/driving/${startLocation.longitude},${startLocation.latitude};$waypoints?overview=full&geometries=geojson';

    try {
      var response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 60));
      var json = jsonDecode(response.body);

      if (json['routes'] == null || json['routes'].isEmpty) {
        setState(() {
          errorMessage = 'No route found';
          isLoading = false;
        });
        return;
      }

      var coordinates = json['routes'][0]['geometry']['coordinates'];

      routeCoordinates.clear();
      for (var coordinate in coordinates) {
        // Ensure coordinates are parsed as doubles
        double lat = coordinate[1].toDouble();
        double lon = coordinate[0].toDouble();
        routeCoordinates.add(LatLng(lat, lon));
      }

      _calculateTotalDistance();
      _saveRoute(); // Save the route after calculating

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching route: $e';
        isLoading = false;
      });
    }
  }

  void _calculateTotalDistance() {
    totalDistance = 0.0;
    for (int i = 0; i < routeCoordinates.length - 1; i++) {
      totalDistance += _calculateDistance(routeCoordinates[i], routeCoordinates[i + 1]);
    }
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double R = 6371e3; // Earth radius in meters
    double lat1 = point1.latitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    double deltaLon = (point2.longitude - point1.longitude) * pi / 180;

    double a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) *
            sin(deltaLon / 2) * sin(deltaLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return R * c;
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    if (selectedLocations.length < 15) {
      selectedLocations.add(latLng);
      setState(() {});
    }
  }

  Future<void> _resetSelection() async {
    bool confirmReset = await _showConfirmationDialog();
    if (confirmReset) {
      selectedLocations.clear();
      routeCoordinates.clear();
      totalDistance = 0.0;
      setState(() {});
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Reset'),
        content: Text('Are you sure you want to reset the selection?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _getLiveLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Geolocator.getPositionStream().listen((Position position) {
      setState(() {
        liveLocation = LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<void> _updateLocations() async {
    selectedLocations.clear();
    for (var controller in _controllers) {
      if (controller.text.isNotEmpty) {
        try {
          LatLng? location = await _getLatLngFromAddress(controller.text);
          if (location != null) {
            selectedLocations.add(location);
          }
        } catch (e) {
          print('Error getting location for ${controller.text}: $e');
        }
      }
    }
    _getRoute();
  }

  Future<LatLng?> _getLatLngFromAddress(String address) async {
    final url = 'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1';
    final response = await http.get(Uri.parse(url));
    final json = jsonDecode(response.body);

    if (json.isNotEmpty) {
      final lat = double.parse(json[0]['lat']);
      final lon = double.parse(json[0]['lon']);
      return LatLng(lat, lon);
    }

    return null;
  }

  Future<void> _saveRoute() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> routeData = routeCoordinates.map((latLng) => jsonEncode({'lat': latLng.latitude, 'lng': latLng.longitude})).toList();
    prefs.setStringList('savedRoute', routeData);
  }

  Future<void> _loadSavedRoutes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedRouteData = prefs.getStringList('savedRoute');

    if (savedRouteData != null) {
      routeCoordinates = savedRouteData.map((data) {
        Map<String, dynamic> parsedData = jsonDecode(data);
        return LatLng(parsedData['lat'], parsedData['lng']);
      }).toList();

      _calculateTotalDistance();
      setState(() {});
    }
  }

  Future<void> _updateStartLocation() async {
    if (_startLocationController.text.isNotEmpty) {
      try {
        LatLng? newStartLocation = await _getLatLngFromAddress(_startLocationController.text);
        if (newStartLocation != null) {
          setState(() {
            startLocation = newStartLocation!;
            routeCoordinates.clear();
            totalDistance = 0.0;
          });
          _getRoute();
        }
      } catch (e) {
        print('Error getting start location: $e');
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _startLocationController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();



  }

  void _removeWaypoint(int index) {
    setState(() {
      selectedLocations.removeAt(index);
      _getRoute();
    });
  }

  void _editWaypoint(int index, LatLng newLocation) {
    setState(() {
      selectedLocations[index] = newLocation;
      _getRoute();
    });
  }



// Function to start listening to voice commands
//   void _startListening() async {
//     bool available = await _speech.initialize(
//       onStatus: (val) => print('onStatus: $val'),
//       onError: (val) => print('onError: $val'),
//     );
//     if (available) {
//       setState(() => _isListening = true);
//       _speech.listen(
//         onResult: (val) => setState(() {
//           _command = val.recognizedWords;
//           _executeCommand(_command);
//         }),
//       );
//     }
//   }

  // Function to stop listening to voice commands
  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }
  // Function to process the voice command
  void _processVoiceCommand(String command) {
    // Implement your custom logic for handling different voice commands here
    // For example:
    if (command.toLowerCase().contains('reset')) {
      _resetSelection();
    } else if (command.toLowerCase().contains('route')) {
      _getRoute();
    }
    // Add more commands as needed
  }

  // Function to speak text using TTS
  Future<void> _speak(String text) async {
    await _flutterTts.speak(text);
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );

    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _command = val.recognizedWords;
        });
        if (!_speech.isListening) {
          setState(() => _isListening = false);
          _executeCommand(_command);
        }
      });
    } else {
      setState(() => _isListening = false);
      print("The user has denied the use of speech recognition.");
    }
  }

  void _executeCommand(String command) async {
    List<String> words = command.split(' ');
    if (words.isEmpty) return;

    String action = words[0].toLowerCase();
    String location = words.sublist(1).join(' ');

    if (action == 'add' && location.isNotEmpty) {
      LatLng? locationCoordinates = await _getLatLngFromAddress(location);
      if (locationCoordinates != null) {
        setState(() {
          if (selectedLocations.length < 15) {
            selectedLocations.add(locationCoordinates);
          }
        });
      }
    } else if (action == 'remove' && location.isNotEmpty) {
      LatLng? locationCoordinates = await _getLatLngFromAddress(location);
      if (locationCoordinates != null) {
        setState(() {
          selectedLocations.removeWhere((loc) => loc.latitude == locationCoordinates.latitude && loc.longitude == locationCoordinates.longitude);
        });
      }
    }
    // Handle other commands if needed
  }


  // void _startListening() async {
  //   bool available = await _speech.initialize(
  //     onStatus: (val) => print('onStatus: $val'),
  //     onError: (val) => print('onError: $val'),
  //   );
  //   if (available) {
  //     setState(() => _isListening = true);
  //     _speech.listen(
  //       onResult: (val) => setState(() {
  //         _command = val.recognizedWords;
  //         print('Recognized command: $_command'); // Debug statement
  //         _executeCommand(_command);
  //       }),
  //     );
  //   }
  // }
  //
  // void _executeCommand(String command) {
  //   command = command.toLowerCase(); // Ensure command is in lower case
  //   print('Executing command: $command'); // Debug statement
  //
  //   if (command.contains('add location')) {
  //     String location = command.split('add location')[1].trim();
  //     _getLatLngFromAddress(location).then((latLng) {
  //       if (latLng != null) {
  //         setState(() {
  //           selectedLocations.add(latLng);
  //         });
  //         _flutterTts.speak('Location added: $location');
  //       } else {
  //         _flutterTts.speak('Could not find location: $location');
  //       }
  //     });
  //   } else if (command.contains('get route')) {
  //     _getRoute();
  //     _flutterTts.speak('Fetching route');
  //   } else if (command.contains('live location')) {
  //     _getLiveLocation();
  //     _flutterTts.speak('Fetching live location');
  //   } else if (command.contains('reset')) {
  //     _resetSelection();
  //     _flutterTts.speak('Resetting selection');
  //   } else {
  //     _flutterTts.speak('Unknown command');
  //   }
  // }

  // Function to execute voice commands


  // Your existing methods here...

  // @override
  // void dispose() {
  //   _speech.stop();
  //   _flutterTts.stop();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Client Meeting Route'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _resetSelection,
          ),
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Enter Locations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _startLocationController,
                decoration: InputDecoration(
                  labelText: 'Start Location (address)',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _updateStartLocation();
                  Navigator.pop(context); // close the drawer
                },
                child: Text('Set Start Location'),
              ),
            ),
            for (int i = 0; i < _controllers.length; i++)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _controllers[i],
                  decoration: InputDecoration(
                    labelText: 'Location ${i + 1} (address)',
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // close the drawer
                  _updateLocations();
                },
                child: Text('Submit'),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (isLoading)
              LinearProgressIndicator(),
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(
              height: 550,
              child: FlutterMap(
                options: MapOptions(
                  center: startLocation,
                  zoom: 13.0,
                  onTap: _onMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routeCoordinates,
                        color: Colors.blue,
                        strokeWidth: 4.0,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (int i = 0; i < selectedLocations.length; i++)
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: selectedLocations[i],
                          builder: (ctx) => GestureDetector(
                            onTap: () async {
                              LatLng? newLocation = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Edit Location'),
                                  content: TextFormField(
                                    controller: _controllers[i],
                                    decoration: InputDecoration(labelText: 'New Location'),
                                  ),
                                  actions: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context, null);
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () async {
                                        LatLng? newLatLng = await _getLatLngFromAddress(_controllers[i].text);
                                        Navigator.pop(context, newLatLng);
                                        _getLiveLocation();
                                      },
                                      child: Text('Submit'),
                                    ),
                                  ],
                                ),
                              );
        
                              if (newLocation != null) {
                                _editWaypoint(i, newLocation);
                              }
                            },
                            child: Container(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.green,
                                size: 40.0,
                              ),
                            ),
                          ),
                        ),
                      if (liveLocation != null)
                        Marker(
                          width: 80.0,
                          height: 80.0,
                          point: liveLocation!,
                          builder: (ctx) => Container(
                            child: Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 40.0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  // TextField(
                  //   controller: _startLocationController,
                  //   decoration: InputDecoration(
                  //     hintText: 'Enter start location',
                  //     suffixIcon: IconButton(
                  //       icon: Icon(Icons.search),
                  //       onPressed: _updateStartLocation,
                  //     ),
                  //   ),
                  // ),
                  // SizedBox(height: 10),
                  // ..._controllers.asMap().entries.map((entry) {
                  //   int index = entry.key;
                  //   TextEditingController controller = entry.value;
                  //   return Row(
                  //     children: [
                  //       Expanded(
                  //         child: TextField(
                  //           controller: controller,
                  //           decoration: InputDecoration(
                  //             hintText: 'Enter location ${index + 1}',
                  //           ),
                  //         ),
                  //       ),
                  //       IconButton(
                  //         icon: Icon(Icons.search),
                  //         onPressed: _updateLocations,
                  //       ),
                  //     ],
                  //   );
                  // }).toList(),
                  SizedBox(height: 10),

                  // if (_isListening)
                  //   IconButton(
                  //     icon: Icon(Icons.mic),
                  //     onPressed: _stopListening,
                  //   )
                  // else
                  //   IconButton(
                  //     icon: Icon(Icons.mic_none),
                  //     onPressed: _startListening,
                  //   ),

                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        'Total Distance: ${(totalDistance / 1000).toStringAsFixed(2)} km',
                        style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        onPressed: (){
                          _getRoute();
                          _getLiveLocation();
                          },

                        child: Text('Calculate Distance'),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      // FloatingActionButton(
                      //   // style: ElevatedButton.styleFrom(
                      //   //   backgroundColor: Colors.blue,
                      //   // ),
                      //   onPressed: _getRoute,
                      //   child: Text('Get Route'),
                      //
                      // ),


          //             FloatingActionButton(
          //   onPressed: _getRoute,
          //   tooltip: 'Get Route',
          //   child: Icon(Icons.directions),
          // ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent,
                        ),
                        onPressed: () => _speak('press recorder say add location example add delhi again press recorder once finished'),
                        child: Text('Mike',style: TextStyle(overflow: TextOverflow.ellipsis,),),
                      ),
                    ],
                  ),

                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}


//All routes in driving mode,reset confirmation,green map symbol which is selected location editable ,starting location.

// Here's a detailed explanation of how each part of the `MapsScreen` widget works:
//
// ### Imports
// - **`flutter/material.dart`**: Provides Flutter's core UI components.
// - **`flutter_map/flutter_map.dart`**: Adds map functionalities.
// - **`flutter_tts/flutter_tts.dart`**: Enables text-to-speech functionality.
// - **`latlong2/latlong.dart`**: Handles latitude and longitude coordinates.
// - **`http/http.dart`**: Manages HTTP requests.
// - **`dart:convert`**: Decodes JSON data.
// - **`dart:math`**: Provides mathematical functions.
// - **`geolocator/geolocator.dart`**: Retrieves geolocation data.
// - **`shared_preferences/shared_preferences.dart`**: Persists simple data across app launches.
// - **`speech_to_text/speech_to_text.dart`**: Manages speech recognition.
//
// ### State Class Initialization
//
// - **`List<LatLng> routeCoordinates`**: Stores the coordinates of the route.
// - **`double totalDistance`**: Keeps track of the total distance of the route.
// - **`LatLng startLocation`**: Default starting location coordinates.
// - **`List<LatLng> selectedLocations`**: List of user-selected locations.
// - **`LatLng? liveLocation`**: Stores the live location of the user.
// - **`bool isLoading`**: Indicates if the app is currently loading data.
// - **`String? errorMessage`**: Stores error messages.
// - **`late stt.SpeechToText _speech`**: Speech-to-text instance.
// - **`late FlutterTts _flutterTts`**: Text-to-speech instance.
// - **`bool _isListening`**: Indicates if the app is currently listening to voice commands.
// - **`String _command`**: Stores the recognized speech command.
// - **`List<TextEditingController> _controllers`**: Controllers for text fields (up to 15 locations).
// - **`TextEditingController _startLocationController`**: Controller for the start location text field.
//
// ### `initState` Method
//
// - Initializes live location fetching, loads saved routes, and sets up speech recognition and text-to-speech instances.
//
// ### Route Calculation
//
// **`_getRoute`**:
// 1. Constructs an API request to fetch the route from selected locations.
// 2. Parses the response and extracts route coordinates.
// 3. Updates the state with the new route coordinates and calculates the total distance.
//
// **`_calculateTotalDistance`**:
// 1. Iterates over the route coordinates and calculates the distance between each pair of points using the Haversine formula.
//
// **`_calculateDistance`**:
// 1. Implements the Haversine formula to calculate the distance between two `LatLng` points.
//
// ### Map Interactions
//
// **`_onMapTap`**:
// 1. Adds a location to the `selectedLocations` list when the map is tapped, if less than 15 locations are selected.
//
// ### Reset Functionality
//
// **`_resetSelection`**:
// 1. Clears the selected locations and route coordinates,
// and resets the total distance after user confirmation.
//
// ### Live Location Fetching
//
// **`_getLiveLocation`**:
// 1. Checks for location service and permission.
// 2. Listens for location updates and updates the `liveLocation` state.
//
// ### Location Handling
//
// **`_updateLocations`**:
// 1. Clears `selectedLocations`.
// 2. Iterates over text field controllers, retrieves coordinates for each address,
// and updates the `selectedLocations` list.
//
// **`_getLatLngFromAddress`**:
// 1. Sends a request to the Nominatim API to get coordinates for an address.
//
// ### Route Persistence
//
// **`_saveRoute`**:
// 1. Saves the current route coordinates to shared preferences.
//
// **`_loadSavedRoutes`**:
// 1. Loads saved route coordinates from shared preferences.
//
// ### Start Location Update
//
// **`_updateStartLocation`**:
// 1. Updates the start location using the address entered in the start location text field.
//
// ### Voice Commands
//
// **`_startListening`**:
// 1. Initializes speech recognition and starts listening for commands.
//
// **`_stopListening`**:
// 1. Stops speech recognition.
//
// **`_executeCommand`**:
// 1. Parses the recognized speech command and executes corresponding actions (e.g., add/remove location).
//
// ### `build` Method
//
// - **`AppBar`**: Contains the title, reset button, and microphone button.
// - **`Drawer`**: Provides a UI for entering and submitting locations.
// - **`FlutterMap`**: Displays the map with markers and the route polyline.
// - **`Column`**: Contains the main UI components, including a progress indicator, error message display, and buttons for calculating distance and speaking text.
//
// ### Marker Interaction
//
// **`MarkerLayer`**:
// 1. Displays markers for selected locations.
// 2. Handles tap events on markers to edit locations.
//
// ### Main Functionality Summary
// 1. **Map Interaction**: Users can select locations on the map.
// 2. **Live Location**: Displays the user’s live location.
// 3. **Route Calculation**: Calculates and displays the route between selected locations.
// 4. **Voice Commands**: Supports adding and removing locations via voice commands.
// 5. **Persistence**: Saves and loads routes across app launches.
// 6. **Text-to-Speech**: Provides voice feedback for commands.
//
// Each component of the `MapsScreen` widget works together to provide a comprehensive route planning tool with map interaction,
// live location tracking, route calculation, and voice command support.
