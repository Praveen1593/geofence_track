import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../main.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initBackgroundLocation() async {
    bg.BackgroundGeolocation.onGeofence((bg.GeofenceEvent event) {
      String status = event.action == 'ENTER' ? 'Entered' : 'Exited';

      print("🚀 Geofence Event: You have $status ${event.identifier}");

      showNotification(status, event.identifier);
      showInAppAlert(status, event.identifier);
      saveMovementHistory(event);
    });

    await bg.BackgroundGeolocation.ready(bg.Config(
      stopOnTerminate: false,
      startOnBoot: true,
      enableHeadless: true,
      geofenceModeHighAccuracy: true,
      distanceFilter: 50,
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
    )).then((bg.State state) {
      if (!state.enabled) {
        bg.BackgroundGeolocation.start();
      }
    });
  }

  void showNotification(String status, String geofenceName) async {
    var androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    var notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      'Geofence Alert',
      'You have $status the geofence: $geofenceName',
      notificationDetails,
    );
  }

  void showInAppAlert(String status, String geofenceName) {
    final BuildContext? context = MyApp.navigatorKey.currentState?.overlay?.context;

    if (context != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Geofence Alert'),
          content: Text('You have $status the geofence: $geofenceName'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            )
          ],
        ),
      );
    }
  }

  void saveMovementHistory(bg.GeofenceEvent event) async {
    var box = await Hive.openBox('movement_history');

    box.add({
      'timestamp': DateTime.now().toString(),
      'lat': event.location?.coords.latitude,
      'lng': event.location?.coords.longitude,
      'status': event.action == 'ENTER' ? 'Inside' : 'Outside',
    });

    print("📍 Movement history updated: You are now ${event.action == 'ENTER' ? 'Inside' : 'Outside'} ${event.identifier}");
  }
  void debugTriggerGeofenceEvent() {
    String status = 'Exited';
    String geofenceName = 'Test Geofence';

    showNotification(status, geofenceName);
    showInAppAlert(status, geofenceName);

    print("🚀 Debug Trigger: User has $status $geofenceName");
  }
}
