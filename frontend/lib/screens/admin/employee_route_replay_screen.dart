// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_map/flutter_map.dart';
// import 'package:latlong2/latlong.dart';
// import '../../services/api_service.dart';

// class EmployeeRouteReplayScreen extends StatefulWidget {
//   final String employeeId;
//   final String date;

//   const EmployeeRouteReplayScreen({
//     Key? key,
//     required this.employeeId,
//     required this.date,
//   }) : super(key: key);

//   @override
//   State<EmployeeRouteReplayScreen> createState() =>
//       _EmployeeRouteReplayScreenState();
// }

// class _EmployeeRouteReplayScreenState extends State<EmployeeRouteReplayScreen> {
//   final ApiService _api = ApiService();
//   final MapController _mapController = MapController();

//   List<LatLng> _route = [];
//   List<Marker> _stopMarkers = [];
//   LatLng? _movingMarkerPosition;

//   Timer? _timer;
//   int _index = 0;
//   bool _isPlaying = false;

//   bool _loading = true;
//   LatLng? _initialPosition;

//   @override
//   void initState() {
//     super.initState();
//     _loadRoute();
//   }

//   Future<void> _loadRoute() async {
//     try {
//       final res = await _api.getEmployeeRoute(widget.employeeId, widget.date);

//       print("🔍 API Response: $res");

//       final route = res["data"]?["route"];
//       final stops = res["data"]?["stops"] ?? [];

//       if (route == null || route.isEmpty) {
//         print("❌ No route data");
//         if (!mounted) return;
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("No route data available")),
//         );
//         return;
//       }

//       // Convert route data to LatLng
//       _route = (route as List).map<LatLng>((p) {
//         final lat = (p["lat"] as num).toDouble();
//         final lng = (p["lng"] as num).toDouble();
//         return LatLng(lat, lng);
//       }).toList();

//       print("✅ Loaded ${_route.length} route points");

//       _initialPosition = _route.first;

//       // Create stop markers
//       for (var s in stops) {
//         final lat = (s["lat"] as num).toDouble();
//         final lng = (s["lng"] as num).toDouble();

//         _stopMarkers.add(
//           Marker(
//             point: LatLng(lat, lng),
//             width: 80,
//             height: 80,
//             child: Column(
//               children: const [
//                 Icon(Icons.local_parking, color: Colors.red, size: 30),
//                 Text(
//                   'Stop',
//                   style: TextStyle(
//                     fontSize: 10,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.red,
//                     backgroundColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }

//       if (!mounted) return;
//       setState(() => _loading = false);
//     } catch (e, stackTrace) {
//       print("❌ Error loading route: $e");
//       print("Stack trace: $stackTrace");
//       if (!mounted) return;
//       Navigator.pop(context);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Failed to load route: $e")));
//     }
//   }

//   void _playReplay() {
//     if (_route.isEmpty) return;

//     setState(() => _isPlaying = true);

//     _timer?.cancel();

//     _timer = Timer.periodic(const Duration(milliseconds: 600), (t) {
//       if (_index >= _route.length) {
//         t.cancel();
//         setState(() => _isPlaying = false);
//         return;
//       }

//       final pos = _route[_index];

//       // Animate map to follow the marker
//       _mapController.move(pos, _mapController.camera.zoom);

//       setState(() {
//         _movingMarkerPosition = pos;
//       });

//       _index++;
//     });
//   }

//   void _pauseReplay() {
//     _timer?.cancel();
//     setState(() => _isPlaying = false);
//   }

//   void _resetReplay() {
//     _timer?.cancel();
//     setState(() {
//       _index = 0;
//       _movingMarkerPosition = null;
//       _isPlaying = false;
//     });
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading || _initialPosition == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text("Driver Route Replay")),
//         body: const Center(child: CircularProgressIndicator()),
//       );
//     }

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Driver Route Replay"),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh),
//             onPressed: _resetReplay,
//             tooltip: 'Reset',
//           ),
//         ],
//       ),
//       body: FlutterMap(
//         mapController: _mapController,
//         options: MapOptions(
//           initialCenter: _initialPosition!,
//           initialZoom: 15.0,
//           minZoom: 5.0,
//           maxZoom: 18.0,
//         ),
//         children: [
//           // Using CartoDB Voyager tiles - completely free, no restrictions
//           TileLayer(
//             urlTemplate:
//                 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
//             maxZoom: 19,
//           ),

//           // Route polyline
//           PolylineLayer(
//             polylines: [
//               Polyline(points: _route, strokeWidth: 4.0, color: Colors.blue),
//             ],
//           ),

//           // Stop markers
//           if (_stopMarkers.isNotEmpty) MarkerLayer(markers: _stopMarkers),

//           // Start marker
//           MarkerLayer(
//             markers: [
//               Marker(
//                 point: _route.first,
//                 width: 40,
//                 height: 40,
//                 child: const Icon(
//                   Icons.play_circle,
//                   color: Colors.green,
//                   size: 40,
//                 ),
//               ),
//             ],
//           ),

//           // End marker
//           MarkerLayer(
//             markers: [
//               Marker(
//                 point: _route.last,
//                 width: 40,
//                 height: 40,
//                 child: const Icon(Icons.flag, color: Colors.red, size: 40),
//               ),
//             ],
//           ),

//           // Moving car marker (shows on top of everything)
//           if (_movingMarkerPosition != null)
//             MarkerLayer(
//               markers: [
//                 Marker(
//                   point: _movingMarkerPosition!,
//                   width: 50,
//                   height: 50,
//                   child: const Icon(
//                     Icons.directions_car,
//                     color: Colors.orange,
//                     size: 50,
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           FloatingActionButton(
//             heroTag: 'play',
//             onPressed: _isPlaying ? null : _playReplay,
//             backgroundColor: _isPlaying ? Colors.grey : Colors.green,
//             child: const Icon(Icons.play_arrow),
//           ),
//           const SizedBox(height: 10),
//           FloatingActionButton(
//             heroTag: 'pause',
//             onPressed: _isPlaying ? _pauseReplay : null,
//             backgroundColor: _isPlaying ? Colors.orange : Colors.grey,
//             child: const Icon(Icons.pause),
//           ),
//           const SizedBox(height: 10),
//           FloatingActionButton(
//             heroTag: 'reset',
//             onPressed: _resetReplay,
//             backgroundColor: Colors.blue,
//             child: const Icon(Icons.replay),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class EmployeeRouteReplayScreen extends StatefulWidget {
  final String employeeId;
  final String date;

  const EmployeeRouteReplayScreen({
    Key? key,
    required this.employeeId,
    required this.date,
  }) : super(key: key);

  @override
  State<EmployeeRouteReplayScreen> createState() =>
      _EmployeeRouteReplayScreenState();
}

class _EmployeeRouteReplayScreenState extends State<EmployeeRouteReplayScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  final MapController _mapController = MapController();

  List<LatLng> _route = [];
  List<LatLng> _smoothRoute = []; // Interpolated route for smooth movement
  List<Map<String, dynamic>> _stops = [];
  List<Marker> _stopMarkers = [];

  LatLng? _movingMarkerPosition;
  double _markerRotation = 0.0;

  Timer? _timer;
  int _index = 0;
  bool _isPlaying = false;
  bool _showJourneyLog = false;

  bool _loading = true;
  LatLng? _initialPosition;

  String? _checkInTime;
  String? _checkOutTime;
  LatLng? _checkInLocation;
  LatLng? _checkOutLocation;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    try {
      final res = await _api.getEmployeeRoute(widget.employeeId, widget.date);

      print("🔍 API Response: $res");

      final route = res["data"]?["route"];
      final stops = res["data"]?["stops"] ?? [];
      final checkIn = res["data"]?["checkIn"];
      final checkOut = res["data"]?["checkOut"];

      if (route == null || route.isEmpty) {
        print("❌ No route data");
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No route data available")),
        );
        return;
      }

      // Convert route data to LatLng
      _route = (route as List).map<LatLng>((p) {
        final lat = (p["lat"] as num).toDouble();
        final lng = (p["lng"] as num).toDouble();
        return LatLng(lat, lng);
      }).toList();

      print("✅ Loaded ${_route.length} route points");

      // Create smooth interpolated route for realistic movement
      _smoothRoute = _interpolateRoute(_route, pointsPerSegment: 10);

      _initialPosition = _route.first;

      // Extract check-in/out info
      if (checkIn != null) {
        _checkInTime = checkIn["time"];
        if (checkIn["lat"] != null && checkIn["lng"] != null) {
          _checkInLocation = LatLng(
            (checkIn["lat"] as num).toDouble(),
            (checkIn["lng"] as num).toDouble(),
          );
        }
      }

      if (checkOut != null) {
        _checkOutTime = checkOut["time"];
        if (checkOut["lat"] != null && checkOut["lng"] != null) {
          _checkOutLocation = LatLng(
            (checkOut["lat"] as num).toDouble(),
            (checkOut["lng"] as num).toDouble(),
          );
        }
      }

      // Store stops
      _stops = (stops as List).map((s) => s as Map<String, dynamic>).toList();

      // Create stop markers
      for (int i = 0; i < _stops.length; i++) {
        final s = _stops[i];
        final lat = (s["lat"] as num).toDouble();
        final lng = (s["lng"] as num).toDouble();

        _stopMarkers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 100,
            height: 100,
            child: GestureDetector(
              onTap: () => _showStopDetails(s),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.deepOrange, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Stop ${i + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(Icons.pause_circle,
                      color: Colors.deepOrange, size: 32),
                ],
              ),
            ),
          ),
        );
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e, stackTrace) {
      print("❌ Error loading route: $e");
      print("Stack trace: $stackTrace");
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load route: $e")),
      );
    }
  }

  // Interpolate route for smooth movement
  List<LatLng> _interpolateRoute(List<LatLng> points,
      {int pointsPerSegment = 10}) {
    if (points.length < 2) return points;

    List<LatLng> interpolated = [];

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      interpolated.add(start);

      for (int j = 1; j < pointsPerSegment; j++) {
        final ratio = j / pointsPerSegment;
        final lat = start.latitude + (end.latitude - start.latitude) * ratio;
        final lng = start.longitude + (end.longitude - start.longitude) * ratio;
        interpolated.add(LatLng(lat, lng));
      }
    }

    interpolated.add(points.last);
    return interpolated;
  }

  // Calculate bearing between two points for marker rotation
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * math.pi / 180;
    final startLng = start.longitude * math.pi / 180;
    final endLat = end.latitude * math.pi / 180;
    final endLng = end.longitude * math.pi / 180;

    final dLng = endLng - startLng;

    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    final bearing = math.atan2(y, x);
    return (bearing * 180 / math.pi + 360) % 360;
  }

  void _playReplay() {
    if (_smoothRoute.isEmpty) return;

    setState(() => _isPlaying = true);
    _animationController.repeat();

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_index >= _smoothRoute.length) {
        t.cancel();
        _animationController.stop();
        setState(() => _isPlaying = false);
        return;
      }

      final pos = _smoothRoute[_index];

      // Calculate rotation for next position
      if (_index < _smoothRoute.length - 1) {
        _markerRotation = _calculateBearing(pos, _smoothRoute[_index + 1]);
      }

      // Smoothly move camera to follow
      _mapController.move(pos, _mapController.camera.zoom);

      setState(() {
        _movingMarkerPosition = pos;
      });

      _index++;
    });
  }

  void _pauseReplay() {
    _timer?.cancel();
    _animationController.stop();
    setState(() => _isPlaying = false);
  }

  void _resetReplay() {
    _timer?.cancel();
    _animationController.stop();
    setState(() {
      _index = 0;
      _movingMarkerPosition = null;
      _isPlaying = false;
      _markerRotation = 0.0;
    });
    if (_initialPosition != null) {
      _mapController.move(_initialPosition!, 15.0);
    }
  }

  void _toggleJourneyLog() {
    setState(() {
      _showJourneyLog = !_showJourneyLog;
    });
  }

  void _showStopDetails(Map<String, dynamic> stop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pause_circle,
                    color: Colors.deepOrange, size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Stop Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.login, 'Arrived', stop['from'] ?? 'N/A'),
            _buildInfoRow(Icons.logout, 'Departed', stop['to'] ?? 'N/A'),
            _buildInfoRow(Icons.timer, 'Duration',
                _calculateDuration(stop['from'], stop['to'])),
            _buildInfoRow(Icons.location_on, 'Location',
                '${(stop['lat'] as num).toStringAsFixed(6)}, ${(stop['lng'] as num).toStringAsFixed(6)}'),
          ],
        ),
      ),
    );
  }

  String _calculateDuration(String? from, String? to) {
    if (from == null || to == null) return 'N/A';
    try {
      final start = DateTime.parse(from);
      final end = DateTime.parse(to);
      final diff = end.difference(start);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      if (hours > 0) {
        return '$hours hr ${minutes} min';
      }
      return '$minutes min';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _initialPosition == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Driver Route Replay"),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Driver Route Replay"),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: _toggleJourneyLog,
            tooltip: 'Journey Log',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetReplay,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition!,
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                maxZoom: 19,
              ),

              // Route polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _route,
                    strokeWidth: 5.0,
                    color: Colors.blue.withOpacity(0.7),
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.white,
                  ),
                ],
              ),

              // Stop markers
              if (_stopMarkers.isNotEmpty) MarkerLayer(markers: _stopMarkers),

              // Check-in marker
              if (_checkInLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _checkInLocation!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.login,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // Check-out marker
              if (_checkOutLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _checkOutLocation!,
                      width: 60,
                      height: 60,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              // Moving car marker with rotation and pulse effect
              if (_movingMarkerPosition != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _movingMarkerPosition!,
                      width: 60,
                      height: 60,
                      child: Transform.rotate(
                        angle: _markerRotation * math.pi / 180,
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (_animationController.value * 0.1),
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.navigation,
                              color: Colors.blue,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Journey Log Panel
          if (_showJourneyLog) _buildJourneyLogPanel(),

          // Play progress indicator
          if (_isPlaying)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progress: ${((_index / _smoothRoute.length) * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _index / _smoothRoute.length,
                        backgroundColor: Colors.grey[300],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'play',
            onPressed: _isPlaying ? null : _playReplay,
            backgroundColor: _isPlaying ? Colors.grey : Colors.green,
            child: const Icon(Icons.play_arrow, size: 32),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'pause',
            onPressed: _isPlaying ? _pauseReplay : null,
            backgroundColor: _isPlaying ? Colors.orange : Colors.grey,
            child: const Icon(Icons.pause, size: 32),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'reset',
            onPressed: _resetReplay,
            backgroundColor: Colors.blue,
            child: const Icon(Icons.replay, size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyLogPanel() {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 8,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Journey Log',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _toggleJourneyLog,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Check-in info
                  if (_checkInTime != null) ...[
                    _buildLogItem(
                      icon: Icons.login,
                      title: 'Check In',
                      time: _formatTime(_checkInTime!),
                      color: Colors.green,
                    ),
                    const Divider(),
                  ],

                  // Stops
                  ...List.generate(_stops.length, (index) {
                    final stop = _stops[index];
                    return Column(
                      children: [
                        _buildLogItem(
                          icon: Icons.pause_circle,
                          title: 'Stop ${index + 1}',
                          time:
                              '${_formatTime(stop["from"] ?? "")} - ${_formatTime(stop["to"] ?? "")}',
                          subtitle:
                              _calculateDuration(stop["from"], stop["to"]),
                          color: Colors.deepOrange,
                        ),
                        const Divider(),
                      ],
                    );
                  }),

                  // Check-out info
                  if (_checkOutTime != null) ...[
                    _buildLogItem(
                      icon: Icons.logout,
                      title: 'Check Out',
                      time: _formatTime(_checkOutTime!),
                      color: Colors.red,
                    ),
                  ],

                  // Summary
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Summary',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryRow('Total Stops', '${_stops.length}'),
                          _buildSummaryRow('Route Points', '${_route.length}'),
                          if (_checkInTime != null && _checkOutTime != null)
                            _buildSummaryRow(
                              'Total Duration',
                              _calculateDuration(_checkInTime, _checkOutTime),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem({
    required IconData icon,
    required String title,
    required String time,
    String? subtitle,
    required Color color,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final dt = DateTime.parse(timeStr);
      return DateFormat('hh:mm a').format(dt);
    } catch (e) {
      return timeStr;
    }
  }
}
