import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive/hive.dart';
import 'package:google_fonts/google_fonts.dart';

import '../Constants/colors.dart';
import '../Services/notification.dart';

class AddGeofenceScreen extends StatefulWidget {
  final Map<String, dynamic>? editGeofence;
  final int? index;

  AddGeofenceScreen({this.editGeofence, this.index});

  @override
  _AddGeofenceScreenState createState() => _AddGeofenceScreenState();
}

class _AddGeofenceScreenState extends State<AddGeofenceScreen> {
  final TextEditingController titleController = TextEditingController();
  double radius = 100;
  LatLng? selectedLocation;
  GoogleMapController? mapController;
  bool isLoading = true;
  List<Map<String, dynamic>> geofences = [];
  String? titleError;

  @override
  void initState() {
    super.initState();
    if (widget.editGeofence != null) {
      titleController.text = widget.editGeofence!['title'];
      radius = widget.editGeofence!['radius'];
      selectedLocation = LatLng(widget.editGeofence!['lat'], widget.editGeofence!['lng']);
      isLoading = false;
    } else {
      _getCurrentLocation();
    }
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

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      selectedLocation = LatLng(position.latitude, position.longitude);
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.editGeofence != null ? 'Edit Geofence' : 'Add Geofence')),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Geofence Title',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: titleError,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Radius: ${radius.toInt()} meters",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Slider(
                      min: 50,
                      max: 500,
                      value: radius,
                      onChanged: (value) {
                        setState(() {
                          radius = value;
                        });

                        // Call checkGeofenceStatus after radius is changed
                        checkGeofenceStatus();
                      },
                      activeColor: Colors.blue,
                      label: '${radius.toStringAsFixed(0)} m',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: selectedLocation!,
                    zoom: 15,
                  ),
                  onMapCreated: (controller) => mapController = controller,
                  onTap: (LatLng pos) => setState(() => selectedLocation = pos),
                  markers: selectedLocation != null
                      ? {
                    Marker(markerId: MarkerId('selected'), position: selectedLocation!)
                  }
                      : {},
                  circles: {
                    Circle(
                      circleId: CircleId('geofence_radius'),
                      center: selectedLocation!,
                      radius: radius,
                      fillColor: Colors.blue.withOpacity(0.3),
                      strokeWidth: 2,
                      strokeColor: Colors.blue,
                    ),
                  },
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    backgroundColor: Colors.white,
                    onPressed: _getCurrentLocation,
                    child: Icon(Icons.my_location, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: lightOrange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
              ),
              onPressed: () async {
                setState(() {
                  titleError = titleController.text.isEmpty ? "Please enter the title" : null;
                });
                if (titleController.text.isEmpty || selectedLocation == null) return;
                var box = await Hive.openBox('geofences');
                if (widget.editGeofence != null) {
                  box.putAt(widget.index!, {
                    'title': titleController.text,
                    'lat': selectedLocation!.latitude,
                    'lng': selectedLocation!.longitude,
                    'radius': radius,
                  });
                } else {
                  box.add({
                    'title': titleController.text,
                    'lat': selectedLocation!.latitude,
                    'lng': selectedLocation!.longitude,
                    'radius': radius,
                  });
                }
                Navigator.pop(context);
              },
              child: Text(
                'Save Geofence',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
