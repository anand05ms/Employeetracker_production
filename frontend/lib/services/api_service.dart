// // lib/services/api_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../models/user.dart';
// import '../models/attendance.dart';

// class ApiService {
//   // ✅ CHANGE THIS TO YOUR IP ADDRESS
//   static const String baseUrl =
//       'https://vickey-neustic-avoidably.ngrok-free.dev/api';

//   // For Android emulator: http://10.0.2.2:5000/api
//   // For real device: http://YOUR_IP:5000/api (e.g., http://192.168.1.4:5000/api)

//   final storage = const FlutterSecureStorage();

//   // ==================== TOKEN MANAGEMENT ====================

//   Future<Map<String, String>> _getHeaders() async {
//     final token = await storage.read(key: 'token');
//     return {
//       'Content-Type': 'application/json',
//       if (token != null) 'Authorization': 'Bearer $token',
//     };
//   }

//   Future<void> saveToken(String token) async {
//     await storage.write(key: 'token', value: token);
//   }

//   Future<String?> getToken() async {
//     return await storage.read(key: 'token');
//   }

//   Future<void> clearToken() async {
//     await storage.delete(key: 'token');
//   }

//   // ==================== AUTHENTICATION ====================

//   // Login
//   Future<Map<String, dynamic>> login(String email, String password) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/auth/login'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'email': email, 'password': password}),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         await saveToken(data['data']['token']);
//         return data;
//       } else {
//         throw Exception(data['message'] ?? 'Login failed');
//       }
//     } catch (e) {
//       throw Exception('Login error: $e');
//     }
//   }

//   // Register
//   Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl/auth/register'),
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode(userData),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 201 && data['success']) {
//         await saveToken(data['data']['token']);
//         return data;
//       } else {
//         throw Exception(data['message'] ?? 'Registration failed');
//       }
//     } catch (e) {
//       throw Exception('Registration error: $e');
//     }
//   }

//   // Get current user
//   Future<User> getCurrentUser() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/auth/me'),
//         headers: headers,
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         return User.fromJson(data['data']['user']);
//       } else {
//         throw Exception(data['message'] ?? 'Failed to fetch user');
//       }
//     } catch (e) {
//       throw Exception('Get user error: $e');
//     }
//   }

//   // ==================== EMPLOYEE ENDPOINTS ====================

//   // Check In
//   Future<Map<String, dynamic>> checkIn(
//     double latitude,
//     double longitude,
//     String address,
//   ) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.post(
//         Uri.parse('$baseUrl/employee/check-in'),
//         headers: headers,
//         body: jsonEncode({
//           'latitude': latitude,
//           'longitude': longitude,
//           'address': address,
//         }),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 201 && data['success']) {
//         return data;
//       } else {
//         throw Exception(data['message'] ?? 'Check-in failed');
//       }
//     } catch (e) {
//       throw Exception('Check-in error: $e');
//     }
//   }

//   // Check Out
//   Future<Map<String, dynamic>> checkOut(
//     double latitude,
//     double longitude,
//     String address,
//   ) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.post(
//         Uri.parse('$baseUrl/employee/check-out'),
//         headers: headers,
//         body: jsonEncode({
//           'latitude': latitude,
//           'longitude': longitude,
//           'address': address,
//         }),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         return data;
//       } else {
//         throw Exception(data['message'] ?? 'Check-out failed');
//       }
//     } catch (e) {
//       throw Exception('Check-out error: $e');
//     }
//   }

//   // Update Location
//   Future<Map<String, dynamic>> updateLocation(
//     double latitude,
//     double longitude,
//     String address,
//   ) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.post(
//         Uri.parse('$baseUrl/employee/location'),
//         headers: headers,
//         body: jsonEncode({
//           'latitude': latitude,
//           'longitude': longitude,
//           'address': address,
//         }),
//       );

//       final data = jsonDecode(response.body);
//       return data;
//     } catch (e) {
//       print('❌ Location update error: $e');
//       return {'success': false, 'message': e.toString()};
//     }
//   }

//   // Get My Status
//   Future<Map<String, dynamic>> getMyStatus() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/employee/status'),
//         headers: headers,
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         return data['data'];
//       } else {
//         throw Exception(data['message'] ?? 'Failed to fetch status');
//       }
//     } catch (e) {
//       throw Exception('Get status error: $e');
//     }
//   }

//   // ==================== ADMIN ENDPOINTS ====================

//   // Get All Employees
//   Future<List<User>> getAllEmployees() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/admin/employees'),
//         headers: headers,
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         // ✅ FIX: Proper type casting
//         final employeesList = data['data']['employees'] as List;
//         return employeesList
//             .map((e) => User.fromJson(e as Map<String, dynamic>))
//             .toList();
//       } else {
//         throw Exception(data['message'] ?? 'Failed to fetch employees');
//       }
//     } catch (e) {
//       print('❌ Error fetching all employees: $e');
//       throw Exception('Get employees error: $e');
//     }
//   }

//   // Get Checked-In Employees (on the way)
//   // In getCheckedInEmployees() method
//   Future<List<dynamic>> getCheckedInEmployees() async {
//     final token = await getToken();

//     // ✅ ADD THIS DEBUG LOG
//     final url = '$baseUrl/admin/checked-in-employees';
//     print('🌐 Calling URL: $url');
//     print('📍 baseUrl is: $baseUrl');

//     final response = await http.get(
//       Uri.parse(url),
//       headers: {
//         'Authorization': 'Bearer $token',
//       },
//     );

//     print('📡 Response status: ${response.statusCode}');
//     print(
//         '📄 Response body: ${response.body.substring(0, 100)}...'); // First 100 chars

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//       return data['data'] ?? [];
//     } else {
//       throw Exception('Failed to get employees');
//     }
//   }

//   // Get Not Checked-In Employees
//   Future<List<User>> getNotCheckedInEmployees() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/admin/not-checked-in-employees'),
//         headers: headers,
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         // ✅ FIX: Proper type casting
//         final employeesList = data['data']['employees'] as List;
//         return employeesList
//             .map((e) => User.fromJson(e as Map<String, dynamic>))
//             .toList();
//       } else {
//         throw Exception(
//             data['message'] ?? 'Failed to fetch not checked-in employees');
//       }
//     } catch (e) {
//       print('❌ Error fetching not checked-in employees: $e');
//       throw Exception('Get not checked-in employees error: $e');
//     }
//   }

//   // Get Reached Employees (in office)
//   Future<List<Map<String, dynamic>>> getReachedEmployees() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/admin/reached-employees'),
//         headers: headers,
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         // ✅ FIX: Proper type casting
//         final employeesList = data['data']['employees'] as List;
//         return employeesList
//             .map((e) => Map<String, dynamic>.from(e as Map))
//             .toList();
//       } else {
//         throw Exception(data['message'] ?? 'Failed to fetch reached employees');
//       }
//     } catch (e) {
//       print('❌ Error fetching reached employees: $e');
//       throw Exception('Get reached employees error: $e');
//     }
//   }

//   // Get Dashboard Stats
//   Future<Map<String, dynamic>> getDashboardStats() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/admin/dashboard-stats'),
//         headers: headers,
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         return Map<String, dynamic>.from(data['data']);
//       } else {
//         throw Exception(data['message'] ?? 'Failed to fetch stats');
//       }
//     } catch (e) {
//       print('❌ Error fetching dashboard stats: $e');
//       throw Exception('Get stats error: $e');
//     }
//   }

//   // ==================== ATTENDANCE HISTORY ====================

//   // Get My Attendance History
//   Future<List<Attendance>> getMyAttendance({
//     DateTime? startDate,
//     DateTime? endDate,
//   }) async {
//     try {
//       final headers = await _getHeaders();
//       String url = '$baseUrl/employee/attendance';

//       if (startDate != null && endDate != null) {
//         url +=
//             '?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
//       }

//       final response = await http.get(
//         Uri.parse(url),
//         headers: headers,
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['success']) {
//         final attendanceList = data['data']['attendance'] as List;
//         return attendanceList
//             .map((e) => Attendance.fromJson(e as Map<String, dynamic>))
//             .toList();
//       } else {
//         throw Exception(data['message'] ?? 'Failed to fetch attendance');
//       }
//     } catch (e) {
//       print('❌ Error fetching attendance: $e');
//       throw Exception('Get attendance error: $e');
//     }
//   }

//   // ==================== UTILITY METHODS ====================

//   // Test Connection
//   Future<bool> testConnection() async {
//     try {
//       final response = await http
//           .get(
//             Uri.parse(baseUrl.replaceAll('/api', '/')),
//           )
//           .timeout(const Duration(seconds: 5));

//       return response.statusCode == 200;
//     } catch (e) {
//       print('❌ Connection test failed: $e');
//       return false;
//     }
//   }

//   // Get Server Status
//   Future<Map<String, dynamic>> getServerStatus() async {
//     try {
//       final response = await http.get(
//         Uri.parse(baseUrl.replaceAll('/api', '/')),
//       );

//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       } else {
//         throw Exception('Server not responding');
//       }
//     } catch (e) {
//       throw Exception('Server status error: $e');
//     }
//   }
// }
// lib/services/api_service.dart

// import 'package:dio/dio.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import '../models/user.dart';
// import '../models/attendance.dart';

// class ApiService {
//   // 🔴 baseUrl already contains /api
//   static const String baseUrl =
//       'https://vickey-neustic-avoidably.ngrok-free.dev/api';

//   final FlutterSecureStorage _storage = const FlutterSecureStorage();

//   late Dio dio;

//   ApiService() {
//     dio = Dio(
//       BaseOptions(
//         baseUrl: baseUrl,
//         connectTimeout: const Duration(seconds: 15),
//         receiveTimeout: const Duration(seconds: 15),
//         headers: {
//           'ngrok-skip-browser-warning': 'true',
//           'Content-Type': 'application/json',
//         },
//       ),
//     );

//     // ✅ AUTO ADD TOKEN TO EVERY REQUEST
//     dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           final token = await getToken();
//           if (token != null) {
//             options.headers["Authorization"] = "Bearer $token";
//           }
//           return handler.next(options);
//         },
//       ),
//     );
//   }

//   // ============================================================
//   // TOKEN HELPERS
//   // ============================================================

//   Future<void> saveToken(String token) async {
//     await _storage.write(key: 'token', value: token);
//   }

//   Future<String?> getToken() async {
//     return await _storage.read(key: 'token');
//   }

//   Future<void> clearToken() async {
//     await _storage.delete(key: 'token');
//   }

//   Future<Map<String, String>> _headers({bool auth = true}) async {
//     final headers = {
//       'Content-Type': 'application/json',
//       'ngrok-skip-browser-warning': 'true',
//     };

//     if (auth) {
//       final token = await getToken();
//       if (token == null) {
//         throw Exception('Auth token missing. Please login again.');
//       }
//       headers['Authorization'] = 'Bearer $token';
//     }

//     return headers;
//   }

//   // ============================================================
//   // AUTH
//   // ============================================================

//   Future<Map<String, dynamic>> login(String email, String password) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/auth/login'),
//       headers: await _headers(auth: false),
//       body: jsonEncode({'email': email, 'password': password}),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final data = jsonDecode(response.body);
//     await saveToken(data['data']['token']);
//     return data;
//   }

//   Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/auth/register'),
//       headers: await _headers(auth: false),
//       body: jsonEncode(userData),
//     );

//     if (response.statusCode != 201) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final data = jsonDecode(response.body);

//     if (data['data']?['token'] != null) {
//       await saveToken(data['data']['token']);
//     }

//     return data;
//   }

//   Future<User> getCurrentUser() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/auth/me'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final data = jsonDecode(response.body);
//     return User.fromJson(data['data']['user']);
//   }

//   // ============================================================
//   // EMPLOYEE
//   // ============================================================

//   Future<Map<String, dynamic>> checkIn(
//     double latitude,
//     double longitude,
//     String address,
//   ) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/employee/check-in'),
//       headers: await _headers(),
//       body: jsonEncode({
//         'latitude': latitude,
//         'longitude': longitude,
//         'address': address,
//       }),
//     );

//     if (response.statusCode != 200 && response.statusCode != 201) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     return jsonDecode(response.body);
//   }

//   Future<Map<String, dynamic>> checkOut(
//     double lat,
//     double lng,
//     String address,
//   ) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/employee/check-out'),
//       headers: await _headers(),
//       body: jsonEncode({'latitude': lat, 'longitude': lng, 'address': address}),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     return jsonDecode(response.body);
//   }

//   Future<Map<String, dynamic>> updateLocation(
//     double lat,
//     double lng,
//     String address,
//   ) async {
//     final response = await http.post(
//       Uri.parse('$baseUrl/employee/location'),
//       headers: await _headers(),
//       body: jsonEncode({'latitude': lat, 'longitude': lng, 'address': address}),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     return jsonDecode(response.body);
//   }

//   Future<Map<String, dynamic>> getMyStatus() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/employee/status'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     return jsonDecode(response.body)['data'];
//   }

//   Future<List<Attendance>> getMyAttendance() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/employee/attendance'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final List list = jsonDecode(response.body)['data']['attendance'];
//     return list.map((e) => Attendance.fromJson(e)).toList();
//   }

//   // ============================================================
//   // ⭐ ROUTE REPLAY (USING DIO)
//   // ============================================================

//   Future<Map<String, dynamic>> getEmployeeRoute(
//       String empId, String date) async {
//     final res = await dio.get(
//       "/admin/employee/$empId/route",
//       queryParameters: {"date": date},
//     );

//     return res.data;
//   }

//   // ============================================================
//   // ADMIN
//   // ============================================================

//   Future<List<User>> getAllEmployees() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/admin/employees'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final List list = jsonDecode(response.body)['data']['employees'];
//     return list.map((e) => User.fromJson(e)).toList();
//   }

//   Future<List<Map<String, dynamic>>> getCheckedInEmployees() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/admin/checked-in-employees'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final List list = jsonDecode(response.body)['data']['employees'];
//     return list.map((e) => Map<String, dynamic>.from(e)).toList();
//   }

//   Future<List<Map<String, dynamic>>> getReachedEmployees() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/admin/reached-employees'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final List list = jsonDecode(response.body)['data']['employees'];
//     return list.map((e) => Map<String, dynamic>.from(e)).toList();
//   }

//   Future<List<Map<String, dynamic>>> getCheckedOutEmployees() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/admin/checked-out-employees'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final List list = jsonDecode(response.body)['data']['employees'];
//     return list.map((e) => Map<String, dynamic>.from(e)).toList();
//   }

//   Future<List<User>> getNotCheckedInEmployees() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/admin/not-checked-in-employees'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     final List list = jsonDecode(response.body)['data']['employees'];
//     return list.map((e) => User.fromJson(e)).toList();
//   }

//   Future<Map<String, dynamic>> getDashboardStats() async {
//     final response = await http.get(
//       Uri.parse('$baseUrl/admin/dashboard-stats'),
//       headers: await _headers(),
//     );

//     if (response.statusCode != 200) {
//       throw Exception(jsonDecode(response.body)['message']);
//     }

//     return jsonDecode(response.body)['data'];
//   }
// }

import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/attendance.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // 🔴 baseUrl already contains /api
  static const String baseUrl = "https://emptracker-backend.onrender.com/api";

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  late Dio dio;

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'ngrok-skip-browser-warning': 'true',
          'Content-Type': 'application/json',
        },
      ),
    );

    // ✅ AUTO ADD TOKEN TO EVERY REQUEST
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await getToken();
          if (token != null) {
            options.headers["Authorization"] = "Bearer $token";
          }
          return handler.next(options);
        },
      ),
    );
  }

  // ============================================================
  // TOKEN HELPERS
  // ============================================================

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'token');
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    if (auth) {
      final token = await getToken();
      if (token == null) {
        throw Exception('Auth token missing. Please login again.');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // ============================================================
  // AUTH
  // ============================================================

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final data = jsonDecode(response.body);
    await saveToken(data['data']['token']);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', data['data']['token']);

    return data;
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(auth: false),
      body: jsonEncode(userData),
    );

    if (response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final data = jsonDecode(response.body);

    if (data['data']?['token'] != null) {
      await saveToken(data['data']['token']);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['data']['token']);
    }

    return data;
  }

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final data = jsonDecode(response.body);
    return User.fromJson(data['data']['user']);
  }

  // ============================================================
  // EMPLOYEE
  // ============================================================

  Future<Map<String, dynamic>> checkIn({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employee/check-in'),
      headers: await _headers(),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> checkOut({
    required double lat,
    required double lng,
    required String address,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employee/check-out'),
      headers: await _headers(),
      body: jsonEncode({'latitude': lat, 'longitude': lng, 'address': address}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> updateLocation(
    double lat,
    double lng,
    String address,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/employee/location'),
      headers: await _headers(),
      body: jsonEncode({'latitude': lat, 'longitude': lng, 'address': address}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMyStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/employee/status'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    return jsonDecode(response.body)['data'];
  }

  Future<Map<String, dynamic>> getTodayTimeline() async {
    final response = await http.get(
      Uri.parse('$baseUrl/employee/timeline'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    return jsonDecode(response.body)['data'];
  }

  Future<List<Attendance>> getMyAttendance() async {
    final response = await http.get(
      Uri.parse('$baseUrl/employee/attendance'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final List list = jsonDecode(response.body)['data']['attendance'];
    return list.map((e) => Attendance.fromJson(e)).toList();
  }

  // ============================================================
  // ⭐ ROUTE REPLAY (USING DIO)
  // ============================================================

  Future<Map<String, dynamic>> getEmployeeRoute(
      String empId, String date) async {
    final res = await dio.get(
      "/admin/employee/$empId/route",
      queryParameters: {"date": date},
    );

    return res.data;
  }

  // ============================================================
  // ADMIN
  // ============================================================

  Future<List<User>> getAllEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/employees'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final List list = jsonDecode(response.body)['data']['employees'];
    return list.map((e) => User.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCheckedInEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/checked-in-employees'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final List list = jsonDecode(response.body)['data']['employees'];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getReachedEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/reached-employees'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final List list = jsonDecode(response.body)['data']['employees'];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getCheckedOutEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/checked-out-employees'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final List list = jsonDecode(response.body)['data']['employees'];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<List<User>> getNotCheckedInEmployees() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/not-checked-in-employees'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    final List list = jsonDecode(response.body)['data']['employees'];
    return list.map((e) => User.fromJson(e)).toList();
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'token');
  }

  // ============================================
  // ENHANCED LOCATION TRACKING
  // ============================================

  /// Update location with speed, altitude, accuracy
  Future<Map<String, dynamic>> updateLocationEnhanced({
    required double latitude,
    required double longitude,
    required String address,
    double? speed,
    double? altitude,
    double? accuracy,
    double? heading,
  }) async {
    final url = Uri.parse('$baseUrl/employee/location-enhanced');

    final token = await getToken();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'speed': speed,
        'altitude': altitude,
        'accuracy': accuracy,
        'heading': heading,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update enhanced location: ${response.body}');
    }
  }

  Future<void> sendRawLocationPayload(String payload) async {
    final token = await getToken();

    if (token == null) {
      throw Exception("No auth token");
    }

    final response = await http.post(
      Uri.parse("$baseUrl/employee/location"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: payload,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to send location");
    }
  }

  // ============================================
  // CONTACT MANAGEMENT
  // ============================================

  /// Get all contacts assigned to current employee
  Future<List<dynamic>> getMyContacts() async {
    final url = Uri.parse('$baseUrl/contacts/my-contacts');
    final token = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['contacts'] ?? [];
    } else {
      throw Exception('Failed to get contacts: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getAttendanceStatus() async {
    final response = await http.get(
      Uri.parse("$baseUrl/employee/status"),
      headers: await _headers(), // ✅ CORRECT
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception("Failed to fetch attendance status");
    }
  }

  /// Add a new contact
  Future<Map<String, dynamic>> addContact({
    required String name,
    required String company,
    String? phone,
    String? email,
    String? address,
    double? latitude,
    double? longitude,
    String? category,
  }) async {
    final url = Uri.parse('$baseUrl/contacts/add');
    final token = await getToken();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'company': company,
        'phone': phone,
        'email': email,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'category': category,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add contact: ${response.body}');
    }
  }

  /// Get contact details
  Future<Map<String, dynamic>> getContact(String contactId) async {
    final url = Uri.parse('$baseUrl/contacts/$contactId');
    final token = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get contact: ${response.body}');
    }
  }

  // ============================================
  // VISIT TRACKING
  // ============================================

  /// Check in to a visit
  Future<Map<String, dynamic>> visitCheckIn({
    required String contactId,
    required double latitude,
    required double longitude,
    required String address,
    String? selfieUrl,
  }) async {
    final url = Uri.parse('$baseUrl/visits/check-in');
    final token = await getToken();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contactId': contactId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'selfie': selfieUrl,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check in: ${response.body}');
    }
  }

  /// Check out from a visit
  Future<Map<String, dynamic>> visitCheckOut({
    required String visitId,
    required double latitude,
    required double longitude,
    int? rating,
    String? remarks,
    String? nextVisitDate,
  }) async {
    final url = Uri.parse('$baseUrl/visits/check-out');
    final token = await getToken();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'visitId': visitId,
        'latitude': latitude,
        'longitude': longitude,
        'rating': rating,
        'remarks': remarks,
        'nextVisitDate': nextVisitDate,
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check out: ${response.body}');
    }
  }

  /// Add photo to visit
  Future<Map<String, dynamic>> addVisitPhoto({
    required String visitId,
    required String photoUrl,
  }) async {
    final url = Uri.parse('$baseUrl/visits/$visitId/photo');
    final token = await getToken();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'photo': photoUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add photo: ${response.body}');
    }
  }

  /// Add notes to visit
  Future<Map<String, dynamic>> addVisitNotes({
    required String visitId,
    String? textNotes,
    String? audioNoteUrl,
  }) async {
    final url = Uri.parse('$baseUrl/visits/$visitId/notes');
    final token = await getToken();

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'textNotes': textNotes,
        'audioNote': audioNoteUrl,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add notes: ${response.body}');
    }
  }

  /// Get my visits (today/this week/this month)
  Future<List<dynamic>> getMyVisits({String period = 'today'}) async {
    final url = Uri.parse('$baseUrl/visits/my-visits?period=$period');
    final token = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['visits'] ?? [];
    } else {
      throw Exception('Failed to get visits: ${response.body}');
    }
  }

  // ============================================
  // LIVE TRACKING (ADMIN)
  // ============================================

  /// Get all employees with their latest location (Admin)
  Future<List<dynamic>> getLiveEmployeeLocations() async {
    final url = Uri.parse('$baseUrl/admin/live-locations');
    final token = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['employees'] ?? [];
    } else {
      throw Exception('Failed to get live locations: ${response.body}');
    }
  }

  /// Get specific employee's live location (Admin)
  Future<Map<String, dynamic>> getEmployeeLiveLocation(
      String employeeId) async {
    final url = Uri.parse('$baseUrl/admin/live-location/$employeeId');
    final token = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get employee location: ${response.body}');
    }
  }

  // ============================================
  // STATISTICS & REPORTS
  // ============================================

  /// Get my statistics
  Future<Map<String, dynamic>> getMyStats({String period = 'today'}) async {
    final url = Uri.parse('$baseUrl/stats/my-stats?period=$period');
    final token = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get stats: ${response.body}');
    }
  }

  /// Get employee report (Admin)
  Future<Map<String, dynamic>> getEmployeeReport({
    required String employeeId,
    required String startDate,
    required String endDate,
  }) async {
    final url = Uri.parse(
        '$baseUrl/admin/report/$employeeId?start=$startDate&end=$endDate');
    final token = await getToken();

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get report: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard-stats'),
      headers: await _headers(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message']);
    }

    return jsonDecode(response.body)['data'];
  }
}
