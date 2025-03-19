import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

import '../Constants/colors.dart';

class MovementHistoryScreen extends StatefulWidget {
  @override
  _MovementHistoryScreenState createState() => _MovementHistoryScreenState();
}

class _MovementHistoryScreenState extends State<MovementHistoryScreen> {
  List<Map<String, dynamic>> movementHistory = [];
  Set<Polyline> polylines = {};
  Set<Marker> markers = {};
  GoogleMapController? _mapController;
  LatLng initialLocation = LatLng(11.004556, 76.961632); // Default to SF

  @override
  void initState() {
    super.initState();
    loadMovementHistory();
  }

  void loadMovementHistory() async {
    var box = await Hive.openBox('movement_history');
    var historyList = box.values.toList().cast<Map<dynamic, dynamic>>();

    if (historyList.isNotEmpty) {
      setState(() {
        movementHistory = historyList.map((entry) {
          return {
            'timestamp': entry['timestamp'],
            'lat': entry['lat'] as double,
            'lng': entry['lng'] as double,
            'status': entry['status'],
          };
        }).toList();

        // Set initial map location to last recorded position
        initialLocation = LatLng(
          movementHistory.last['lat'],
          movementHistory.last['lng'],
        );

        // Generate polyline
        polylines = {
          Polyline(
            polylineId: PolylineId('movement_route'),
            color: Colors.blueAccent,
            width: 6,
            points: movementHistory
                .map((entry) => LatLng(entry['lat'], entry['lng']))
                .toList(),
            patterns: [PatternItem.dash(12), PatternItem.gap(6)], // Dotted Line
          ),
        };

        // Generate markers
        markers = movementHistory.map((entry) {
          return Marker(
            markerId: MarkerId(entry['timestamp']),
            position: LatLng(entry['lat'], entry['lng']),
            infoWindow: InfoWindow(
              title: 'Location Update',
              snippet: "Status: ${entry['status']}",
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              entry['status'] == "Inside" ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
          );
        }).toSet();
      });

      // Move camera to last recorded location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(initialLocation, 14),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('Movement History',style: TextStyle(color: Colors.white),),
        backgroundColor: lightOrange,
        elevation: 4,
      ),
      body: Column(
        children: [
          // MAP DISPLAY
          Expanded(
            flex: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialLocation,
                  zoom: 14,
                ),
                polylines: polylines,
                markers: markers,
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (movementHistory.isNotEmpty) {
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(initialLocation, 14),
                    );
                  }
                },
              ),
            ),
          ),

          // MOVEMENT HISTORY LIST
          Expanded(
            flex: 1,
            child: ListView.builder(
              padding: EdgeInsets.all(10),
              itemCount: movementHistory.length,
              itemBuilder: (context, index) {
                var entry = movementHistory[index];
                bool isInside = entry['status'] == "Inside";
                String formattedTime = DateFormat('MMM dd, hh:mm a')
                    .format(DateTime.parse(entry['timestamp']));

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isInside ? Colors.green : Colors.red,
                      child: Icon(
                        isInside ? Icons.check_circle : Icons.warning,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      formattedTime,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Lat: ${entry['lat']}, Lng: ${entry['lng']}'),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isInside ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        entry['status'],
                        style: TextStyle(
                          color: isInside ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
