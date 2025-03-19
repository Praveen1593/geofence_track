# Geofence Tracking App

A Flutter application that allows users to create and manage geofences, track movement history, and receive notifications when entering or exiting a geofenced area.

## 🚀 Features
- Add, edit, and delete geofences with a specified radius.
- Background location tracking for geofence entry/exit.
- Local notifications and in-app alerts when entering or exiting a geofenced area.
- Store movement history using Hive.
- Interactive Google Maps integration with real-time location updates.

## 🛠️ Setup Instructions

### Prerequisites
Ensure you have the following installed:
- [Flutter](https://flutter.dev/docs/get-started/install) (Latest stable version recommended)
- Android Studio or Xcode (for running on physical/emulator devices)
- A physical Android/iOS device (for background location testing)

### Installation Steps
1. **Clone the repository:**
   ```sh
   git clone https://github.com/your-repo/geofence-app.git
   cd geofence-app
   ```

2. **Install dependencies:**
   ```sh
   flutter pub get
   ```

3. **Set up required permissions:**
    - **Android:** Modify `AndroidManifest.xml` to include location permissions and background services.
    - **iOS:** Update `Info.plist` with location permissions.

4. **Run the application:**
   ```sh
   flutter run
   ```

## 📦 Required Dependencies
Ensure these dependencies are added to `pubspec.yaml`:


dependencies:
  flutter:
    sdk: flutter
  google_maps_flutter: ^2.2.5
  geolocator: ^9.0.2
  hive: ^2.2.3
  flutter_local_notifications: ^14.0.0
  flutter_background_geolocation: ^1.0.0
  google_fonts: ^5.1.0
```

## 🧪 Testing Guidelines

### Manual Testing Steps
1. **Add a Geofence**
    - Open the app and navigate to the **Add Geofence** screen.
    - Enter a title, select a location, and set the radius.
    - Tap **Save Geofence**.

2. **Verify Entry & Exit Notifications**
    - Move into the geofenced area → Expect a notification and alert.
    - Move out of the geofenced area → Expect another notification.

3. **Check Movement History**
    - Navigate to the **Movement History** screen.
    - Verify that each movement entry (inside/outside) is logged with a timestamp.

4. **Test Background Location Tracking**
    - Close the app and move around (ensure background location is enabled).
    - Reopen the app and check movement history for updates.

## 📌 Notes
- Ensure location services and permissions are enabled on your device.
- For background tracking, enable **Auto-start** in device settings (for Android).
- Location updates might be delayed due to device power optimizations.



