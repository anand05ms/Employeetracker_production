// // lib/services/background_location_service.dart
// import 'dart:async';
// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:flutter_background_service_android/flutter_background_service_android.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// class BackgroundLocationService {
//   static const String _channelId = 'location_tracking_channel';
//   static const String _channelName = 'Location Tracking';
//   static const int _notificationId = 888;

//   final FlutterBackgroundService _service = FlutterBackgroundService();

//   // Start background tracking
//   Future<void> start({
//     required String userId,
//     required String userName,
//   }) async {
//     // Initialize service
//     await _initializeService();

//     // Store user info
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString('user_id', userId);
//     await prefs.setString('user_name', userName);
//     await prefs.setBool('is_tracking', true);

//     // Start the service
//     await _service.startService();

//     print('🟢 Background service started for $userName');
//   }

//   // Stop background tracking
//   Future<void> stop() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool('is_tracking', false);

//     _service.invoke('stop'); // Don't await - returns void
//     print('🔴 Background service stop signal sent');
//   }

//   // Check if service is running
//   Future<bool> isRunning() async {
//     return await _service.isRunning();
//   }

//   // Get pending location updates from SharedPreferences
//   Future<List<Map<String, dynamic>>> getPendingUpdates() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final queueJson = prefs.getString('location_queue') ?? '[]';
//       final decoded = jsonDecode(queueJson);

//       if (decoded is List) {
//         return List<Map<String, dynamic>>.from(
//             decoded.map((item) => Map<String, dynamic>.from(item)));
//       }
//       return [];
//     } catch (e) {
//       print('❌ Error getting pending updates: $e');
//       return [];
//     }
//   }

//   // Clear processed updates
//   Future<void> clearPendingUpdates() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setString('location_queue', '[]');
//       print('✅ Cleared pending updates');
//     } catch (e) {
//       print('❌ Error clearing updates: $e');
//     }
//   }

//   // Initialize the background service
//   Future<void> _initializeService() async {
//     final service = FlutterBackgroundService();

//     // Create notification channel (Android)
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       _channelId,
//       _channelName,
//       description: 'Tracking your location for attendance',
//       importance: Importance.low,
//       playSound: false,
//     );

//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     await service.configure(
//       androidConfiguration: AndroidConfiguration(
//         onStart: onStart,
//         autoStart: false,
//         isForegroundMode: true,
//         notificationChannelId: _channelId,
//         initialNotificationTitle: 'Location Tracking Active',
//         initialNotificationContent: 'Tracking your location...',
//         foregroundServiceNotificationId: _notificationId,
//       ),
//       iosConfiguration: IosConfiguration(
//         autoStart: false,
//         onForeground: onStart,
//         onBackground: onIosBackground,
//       ),
//     );
//   }

//   // iOS background handler
//   @pragma('vm:entry-point')
//   static Future<bool> onIosBackground(ServiceInstance service) async {
//     return true;
//   }

//   // Main background service entry point
//   @pragma('vm:entry-point')
//   static void onStart(ServiceInstance service) async {
//     print('🟢 Background service started');

//     // Track service state
//     bool isServiceRunning = true;

//     if (service is AndroidServiceInstance) {
//       service.on('stop').listen((event) {
//         isServiceRunning = false;
//         service.stopSelf();
//         print('🔴 Service stopped by user');
//       });

//       service.setAsForegroundService();
//     }

//     // Get user info
//     final prefs = await SharedPreferences.getInstance();
//     final userId = prefs.getString('user_id') ?? '';
//     final userName = prefs.getString('user_name') ?? 'Employee';

//     print('👤 Tracking for: $userName ($userId)');

//     // Timer for periodic location updates
//     Timer.periodic(const Duration(seconds: 30), (timer) async {
//       if (!isServiceRunning) {
//         timer.cancel();
//         return;
//       }

//       // Check if tracking is still enabled
//       final isTracking = prefs.getBool('is_tracking') ?? false;
//       if (!isTracking) {
//         print('⏸️ Tracking disabled');
//         timer.cancel();
//         return;
//       }

//       try {
//         // Get current location
//         final position = await Geolocator.getCurrentPosition(
//           desiredAccuracy: LocationAccuracy.high,
//           timeLimit: const Duration(seconds: 10),
//         ).timeout(const Duration(seconds: 15));

//         print('📍 BG Location: ${position.latitude}, ${position.longitude}');

//         // Save location to SharedPreferences
//         await _saveLocationUpdate(
//           position.latitude,
//           position.longitude,
//           prefs,
//         );

//         // Update notification
//         if (service is AndroidServiceInstance) {
//           service.setForegroundNotificationInfo(
//             title: 'Location Tracking Active',
//             content:
//                 'Last update: ${DateTime.now().toString().substring(11, 19)} | Distance: ${position.accuracy.toInt()}m',
//           );
//         }
//       } catch (e) {
//         print('❌ Background location error: $e');

//         // Update notification with error
//         if (service is AndroidServiceInstance) {
//           service.setForegroundNotificationInfo(
//             title: 'Location Tracking Active',
//             content: 'Waiting for GPS signal...',
//           );
//         }
//       }
//     });
//   }

//   // Save location update to SharedPreferences
//   static Future<void> _saveLocationUpdate(
//     double lat,
//     double lng,
//     SharedPreferences prefs,
//   ) async {
//     try {
//       final update = {
//         'latitude': lat,
//         'longitude': lng,
//         'timestamp': DateTime.now().toIso8601String(),
//       };

//       // Save latest location
//       await prefs.setString('latest_location', jsonEncode(update));

//       // Add to pending queue
//       final queueJson = prefs.getString('location_queue') ?? '[]';
//       List<dynamic> queue;

//       try {
//         queue = jsonDecode(queueJson);
//       } catch (e) {
//         print('❌ Error decoding queue, resetting: $e');
//         queue = [];
//       }

//       queue.add(update);

//       // Keep only last 200 updates
//       if (queue.length > 200) {
//         queue = queue.sublist(queue.length - 200);
//       }

//       await prefs.setString('location_queue', jsonEncode(queue));
//       print('📦 Saved to local queue (${queue.length} pending)');
//     } catch (e) {
//       print('❌ Error saving location: $e');
//     }
//   }
// }

// lib/services/background_location_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'persistent_queue_service.dart';

class BackgroundLocationService {
  static const String _baseUrl = "https://emptracker-backend.onrender.com/api";
  static const int _interval = 10;
  static const String _channelId = "tracking_channel";
  static const int _notificationId = 999;

  final FlutterBackgroundService _service = FlutterBackgroundService();

  // ============================================================
  // PUBLIC METHODS (USED BY UI)
  // ============================================================

  Future<void> start({
    required String userId,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setBool('is_tracking', true);

    await _configureService();

    await _service.startService();
    print("🟢 Background tracking started");
  }

  Future<void> stop() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_tracking', false);
    _service.invoke("stop");
    print("🔴 Background tracking stopped");
  }

  Future<bool> isRunning() async {
    return await _service.isRunning();
  }

  Future<List<Map<String, dynamic>>> getPendingUpdates() async {
    final queue = PersistentQueueService();
    await queue.initialize();
    return [];
  }

  Future<void> clearPendingUpdates() async {
    final queue = PersistentQueueService();
    await queue.clearQueue();
  }

  // ============================================================
  // SERVICE CONFIG
  // ============================================================

  Future<void> _configureService() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      "Location Tracking",
      description: "Background location tracking",
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    await notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: "Tracking Active",
        initialNotificationContent: "Location tracking running",
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
      ),
    );
  }

  // ============================================================
  // BACKGROUND ENTRY POINT
  // ============================================================

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    final queue = PersistentQueueService();
    await queue.initialize();

    final prefs = await SharedPreferences.getInstance();

    if (service is AndroidServiceInstance) {
      service.on('stop').listen((event) {
        service.stopSelf();
      });

      service.setAsForegroundService();
    }

    Timer.periodic(const Duration(seconds: _interval), (timer) async {
      final isTracking = prefs.getBool('is_tracking') ?? false;
      if (!isTracking) {
        timer.cancel();
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final token = prefs.getString('token');
        if (token == null) {
          print("❌ No token available");
          return;
        }

        final payload = {
          "latitude": position.latitude,
          "longitude": position.longitude,
          "speed": position.speed * 3.6,
          "altitude": position.altitude,
          "accuracy": position.accuracy,
          "heading": position.heading,
          "timestamp": DateTime.now().toIso8601String(),
          "address": "Background",
        };

        // Try direct send
        try {
          final res = await http.post(
            Uri.parse("$_baseUrl/employee/location-enhanced"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            },
            body: jsonEncode(payload),
          );

          if (res.statusCode != 200 && res.statusCode != 201) {
            throw Exception("Server rejected");
          }

          print("✅ Sent location to server");
        } catch (_) {
          print("⚠️ Offline, saving to queue");
          await queue.addLocationUpdate(
            payload["latitude"] as double,
            payload["longitude"] as double,
            jsonEncode(payload),
            payload["timestamp"] as String,
          );
        }

        // Always attempt flush
        await queue.flush((lat, lng, address, timestamp) async {
          final decoded = jsonDecode(address);
          await http.post(
            Uri.parse("$_baseUrl/employee/location-enhanced"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token"
            },
            body: jsonEncode(decoded),
          );
        });
      } catch (e) {
        print("❌ Background error: $e");
      }
    });
  }
}
