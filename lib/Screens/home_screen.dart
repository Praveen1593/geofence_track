import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../Constants/colors.dart';
import '../Services/location.dart';
import '../Services/notification.dart';
import 'addgeofence_screen.dart';
import 'history_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> geofences = [];
  Position? currentPosition;


  @override
  void initState() {
    super.initState();
    _checkPermissions();
    loadGeofences();
    checkGeofenceStatus();
    LocationService().initBackgroundLocation();
    Timer.periodic(Duration(minutes: 2), (timer) {
      checkGeofenceStatus();
    });

  }
  void _checkPermissions() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _showPermissionError();
    } else {
      _getCurrentLocation();
    }
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Location permission is required for geofencing.")),
    );
  }

  void _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => currentPosition = position);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Geofences',
          style: GoogleFonts.poppins(fontSize: 20, color: Colors.white),
        ),
        backgroundColor:lightOrange,
        elevation: 4,
      ),
      body: Column(
        children: [
          Expanded(
            child: geofences.isEmpty
                ? Center(
              child: Text(
                "No geofences added yet!",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: geofences.length,
              itemBuilder: (context, index) {
                var geofence = geofences[index];
                bool isInside = geofence['status'] == 'Inside';

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          geofence['title'],
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(width: 20),
                        Chip(
                          label: Text(
                            geofence['status']?.toString() ?? 'Unknown',
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w500, color: isInside ? Colors.green : Colors.red),
                          ),
                          backgroundColor: isInside ? Colors.green[100] : Colors.red[100],
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Lat: ${geofence['lat']}, Lng: ${geofence['lng']}\nRadius: ${geofence['radius']}m',
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        IconButton(
                          icon: Icon(Icons.edit, color: lightOrange),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddGeofenceScreen(editGeofence: geofence, index: index),
                              ),
                            ).then((_) => loadGeofences());
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            var box = await Hive.openBox('geofences');
                            box.deleteAt(index);
                            loadGeofences();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, blurRadius: 5, offset: Offset(0, -2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[900],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.history, color: Colors.white),
                  label: Text("Movement History", style: GoogleFonts.poppins(color: Colors.white)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MovementHistoryScreen()),
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: lightOrange,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text("Add Geofence", style: GoogleFonts.poppins(color: Colors.white)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddGeofenceScreen()),
                  ).then((_) => loadGeofences()),
                ),


              ],
            ),
          ),
        ],
      ),
    );
  }
  void loadGeofences() async {
    var box = await Hive.openBox('geofences');
    setState(() {
      geofences = box.values.map((e) => Map<String, dynamic>.from(e)).toList();
    });
  }

  void checkGeofenceStatus() async {


    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    var box = await Hive.openBox('movement_history');

    for (var i = 0; i < geofences.length; i++) {
      var geofence = geofences[i];

      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence['lat'] as double,
        geofence['lng'] as double,
      );

      String newStatus = distance <= (geofence['radius'] as double) ? 'Inside' : 'Outside';

      if (geofences[i]['status'] != newStatus) {
        // Send notification on status change
        await NotificationService().showNotification(
            "Geofence Alert", "You are now $newStatus ${geofence['title']}");

        // Show in-app alert
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Geofence Status Changed"),
              content: Text("You are now $newStatus ${geofence['title']}"),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("OK"),
                )
              ],
            ),
          );
        }

        // Update geofence status
        setState(() {
          geofences[i]['status'] = newStatus;
        });

        // Store movement in history
        box.add({
          'timestamp': DateTime.now().toString(),
          'lat': position.latitude,
          'lng': position.longitude,
          'status': newStatus,
        });


      }
    }
  }
}



