// // lib/services/background_location_service.dart
// import 'dart:async';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'api_service.dart';

// class BackgroundLocationService {
//   static final BackgroundLocationService _instance =
//       BackgroundLocationService._internal();
//   factory BackgroundLocationService() => _instance;
//   BackgroundLocationService._internal();

//   final ApiService _apiService = ApiService();
//   StreamSubscription<Position>? _positionSubscription;
//   bool _isTracking = false;

//   // Start tracking location
//   Future<void> startTracking() async {
//     if (_isTracking) {
//       print('⚠️ Already tracking location');
//       return;
//     }

//     print('🎯 Starting background location tracking...');
//     _isTracking = true;

//     // Listen to position stream (updates every 10 meters)
//     _positionSubscription = Geolocator.getPositionStream(
//       locationSettings: const LocationSettings(
//         accuracy: LocationAccuracy.high,
//         distanceFilter: 10, // Update every 10 meters
//       ),
//     ).listen(
//       (Position position) async {
//         print(
//             '📍 Location changed: ${position.latitude}, ${position.longitude}');
//         await _sendLocationUpdate(position);
//       },
//       onError: (error) {
//         print('❌ Location stream error: $error');
//       },
//     );

//     print('✅ Background location tracking started');
//   }

//   // Send location update to backend
//   Future<void> _sendLocationUpdate(Position position) async {
//     try {
//       // Get address from coordinates
//       String address = 'Moving';
//       try {
//         List<Placemark> placemarks = await placemarkFromCoordinates(
//           position.latitude,
//           position.longitude,
//         );
//         if (placemarks.isNotEmpty) {
//           final place = placemarks.first;
//           address = '${place.street ?? ''}, ${place.locality ?? ''}';
//         }
//       } catch (e) {
//         print('⚠️ Failed to get address: $e');
//       }

//       print('🚀 Sending location update to backend...');

//       final response = await _apiService.updateLocation(
//         position.latitude,
//         position.longitude,
//         address,
//       );

//       if (response['success']) {
//         print('✅ Location update sent successfully');

//         // Check if reached office
//         if (response['data']?['hasReachedOffice'] == true) {
//           print('🎉 Employee reached office!');
//           await stopTracking(); // Stop tracking when reached
//         }
//       } else {
//         print('⚠️ Location update failed: ${response['message']}');
//       }
//     } catch (e) {
//       print('❌ Error sending location update: $e');
//     }
//   }

//   // Stop tracking
//   Future<void> stopTracking() async {
//     print('🛑 Stopping background location tracking...');
//     await _positionSubscription?.cancel();
//     _positionSubscription = null;
//     _isTracking = false;
//     print('✅ Background location tracking stopped');
//   }

//   // Check if currently tracking
//   bool get isTracking => _isTracking;
// }
// lib/services/background_location_service.dart
// lib/services/background_location_service.dart
import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BackgroundLocationService {
  static const String _channelId = 'location_tracking_channel';
  static const String _channelName = 'Location Tracking';
  static const int _notificationId = 888;

  final FlutterBackgroundService _service = FlutterBackgroundService();

  // Start background tracking
  Future<void> start({
    required String userId,
    required String userName,
    required Function(double lat, double lng) onLocationUpdate,
  }) async {
    // Initialize service
    await _initializeService();

    // Store callback info (we'll use SharedPreferences for communication)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_name', userName);

    // Start the service
    await _service.startService();

    print('🟢 Background service started for $userName');
  }

  // Stop background tracking

  Future<void> stop() async {
    _service.invoke('stop');
    print('🔴 Background service stopped');
  }

  // Check if service is running
  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  // Initialize the background service
  Future<void> _initializeService() async {
    final service = FlutterBackgroundService();

    // Create notification channel (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Tracking your location for attendance',
      importance: Importance.low,
      playSound: false,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true, // CRITICAL: Run as foreground service
        notificationChannelId: _channelId,
        initialNotificationTitle: 'Location Tracking Active',
        initialNotificationContent: 'Tracking your location...',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  // iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  // Main background service entry point
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    print('🟢 Background service started');

    if (service is AndroidServiceInstance) {
      service.on('stop').listen((event) {
        service.stopSelf();
        print('🔴 Service stopped by user');
      });

      service.setAsForegroundService();
    }

    // Get user info from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final userName = prefs.getString('user_name') ?? 'Employee';

    // Track if service should continue running
    bool isServiceRunning = true;

    service.on('stop').listen((event) {
      isServiceRunning = false;
    });

    // Timer for periodic location updates
    Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!isServiceRunning) {
        timer.cancel();
        return;
      }

      try {
        // Get current location
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        print('📍 BG Location: ${position.latitude}, ${position.longitude}');

        // Store location in shared preferences for main app to pick up
        await _saveLocationUpdate(
          position.latitude,
          position.longitude,
          prefs,
        );

        // Update notification
        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'Location Tracking Active',
            content:
                'Last update: ${DateTime.now().toString().substring(11, 19)}',
          );
        }
      } catch (e) {
        print('❌ Background location error: $e');
      }
    });
  }

  // Save location update to shared preferences
  static Future<void> _saveLocationUpdate(
    double lat,
    double lng,
    SharedPreferences prefs,
  ) async {
    final update = {
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Save latest location
    await prefs.setString('latest_location', jsonEncode(update));

    // Add to pending queue
    final queueJson = prefs.getString('location_queue') ?? '[]';
    final queue = List<Map<String, dynamic>>.from(jsonDecode(queueJson));
    queue.add(update);

    // Keep only last 100 updates
    if (queue.length > 100) {
      queue.removeRange(0, queue.length - 100);
    }

    await prefs.setString('location_queue', jsonEncode(queue));
    print('📦 Saved to local queue (${queue.length} pending)');
  }

  // Get pending location updates from shared preferences
  Future<List<Map<String, dynamic>>> getPendingUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString('location_queue') ?? '[]';
    return List<Map<String, dynamic>>.from(jsonDecode(queueJson));
  }

  // Clear processed updates
  Future<void> clearPendingUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('location_queue', '[]');
  }
}
