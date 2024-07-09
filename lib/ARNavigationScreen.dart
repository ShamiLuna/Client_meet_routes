// import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
// import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
// import 'package:flutter/material.dart';
// import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
// import 'package:ar_flutter_plugin/datatypes/node_types.dart';
// import 'package:ar_flutter_plugin/models/ar_node.dart';
// import 'package:latlong2/latlong.dart';
// import 'package:vector_math/vector_math_64.dart'; // Import for Vector3
//
// class ARNavigationScreen extends StatefulWidget {
//   final List<LatLng> routeCoordinates;
//
//   ARNavigationScreen({required this.routeCoordinates});
//
//   @override
//   _ARNavigationScreenState createState() => _ARNavigationScreenState();
// }
//
// class _ARNavigationScreenState extends State<ARNavigationScreen> {
//   late ARSessionManager arSessionManager;
//   late ARObjectManager arObjectManager;
//   List<ARNode> arNodes = [];
//
//   @override
//   void dispose() {
//     arSessionManager.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('AR Navigation'),
//       ),
//       body: ARView(
//         onARViewCreated: onARViewCreated,
//         planeDetectionConfig: PlaneDetectionConfig.horizontal,
//       ),
//     );
//   }
//
//   void onARViewCreated(
//       ARSessionManager arSessionManager,
//       ARObjectManager arObjectManager,
//       ARAnchorManager arAnchorManager,
//       ARLocationManager arLocationManager,
//       ) {
//     this.arSessionManager = arSessionManager;
//     this.arObjectManager = arObjectManager;
//
//     arSessionManager.onInitialize(
//       showFeaturePoints: false,
//       showPlanes: false,
//       customPlaneTexturePath: null,
//       showWorldOrigin: true,
//       handleTaps: false,
//     );
//
//     _addRouteNodes();
//   }
//
//   void _addRouteNodes() {
//     for (LatLng point in widget.routeCoordinates) {
//       _addNode(point);
//     }
//   }
//
//   void _addNode(LatLng point) async {
//     var newNode = ARNode(
//       type: NodeType.localGLTF2,
//       uri: "assets/arrow.glb",
//       position: Vector3(point.latitude, 0, point.longitude),
//       scale: Vector3(0.1, 0.1, 0.1),
//     );
//
//     bool? didAddNode = await arObjectManager.addNode(newNode);
//     if (didAddNode == true) {
//       arNodes.add(newNode);
//     }
//   }
// }
