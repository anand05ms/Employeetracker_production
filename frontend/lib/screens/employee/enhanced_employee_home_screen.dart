// lib/screens/employee/enhanced_employee_home_screen.dart
// COMPLETE REPLACEMENT for employee_home_screen.dart
// Premium UI like BlackBuck + DayTrack

import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/background_location_service.dart';
import '../../services/persistent_queue_service.dart';
import '../../services/geocoding_service.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/timeline_widget.dart';
import '../../widgets/loading_effects.dart';
import '../../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../services/auth_provider.dart';
import '../auth/login_screen.dart';

class EnhancedEmployeeHomeScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const EnhancedEmployeeHomeScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  @override
  State<EnhancedEmployeeHomeScreen> createState() =>
      _EnhancedEmployeeHomeScreenState();
}

class _EnhancedEmployeeHomeScreenState extends State<EnhancedEmployeeHomeScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  // Services
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  final BackgroundLocationService _bgLocationService =
      BackgroundLocationService();
  final PersistentQueueService _queueService = PersistentQueueService();
  final GeocodingService _geocodingService = GeocodingService();

  // State variables
  bool _isCheckedIn = false;
  bool _isTracking = false;
  bool _isLoading = false;
  bool _isLoadingStats = false;

  // Location data
  Position? _currentPosition;
  String _currentAddress = 'Fetching location...';
  double _currentSpeed = 0.0;

  // Stats
  double _todayDistance = 0.0;
  int _todayVisits = 0;
  int _todayDuration = 0; // minutes
  double _avgSpeed = 0.0;
  double _maxSpeed = 0.0;
  int _pendingUpdates = 0;

  // Today's journey timeline
  List<TimelineItem> _todayTimeline = [];

  // Timers
  Timer? _statsTimer;
  Timer? _locationTimer;

  // Animation
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _initializeServices();
    _loadStatus();
    _getCurrentLocation();
    _fetchTodayStats();
    _fetchTodayTimeline();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _statsTimer?.cancel();
    _locationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print('📱 App resumed → refreshing all data');
      _loadStatus();
      _getCurrentLocation();
      _fetchTodayStats();
    }
  }

  // ============================================
  // INITIALIZATION
  // ============================================

  Future<void> _initializeServices() async {}

  void _startPeriodicUpdates() {
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      await _fetchTodayStats();
      await _updateCurrentLocation();

      final size = await _queueService.queueSize;
      if (mounted) {
        setState(() {
          _pendingUpdates = size;
        });
      }
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      await _updateCurrentLocation();
    });
  }

  Future<bool> _ensureLocationEnabled() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1️⃣ Check if GPS service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showEnableGpsDialog();
      return false;
    }

    // 2️⃣ Check permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission denied', Colors.red);
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showOpenSettingsDialog();
      return false;
    }

    return true;
  }

  void _showEnableGpsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enable GPS'),
        content: const Text(
          'Location services are disabled. Please enable GPS to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open App Settings'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // LOAD STATUS
  // ============================================

  Future<void> _loadStatus() async {
    try {
      final isRunning = await _bgLocationService.isRunning();
      final response = await _apiService.getAttendanceStatus();

      setState(() {
        _isTracking = isRunning;
        _isCheckedIn = response['isCheckedIn'] ?? false;
      });

      print('📊 Status loaded: CheckedIn=$_isCheckedIn, Tracking=$_isTracking');

      // If checked in but not tracking, start tracking
      if (_isCheckedIn && !_isTracking) {
        print('⚠️ Checked in but not tracking, restarting...');
        await _startBackgroundTracking();
      }
    } catch (e) {
      print('❌ Error loading status: $e');
    }
  }

  // ============================================
  // LOCATION UPDATES
  // ============================================

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        setState(() {
          _currentPosition = position;
          _currentSpeed = position.speed * 3.6; // m/s to km/h
        });

        // Get address
        final address = await _geocodingService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        setState(() {
          _currentAddress = address;
        });

        print('📍 Location: ${position.latitude}, ${position.longitude}');
        print('🏠 Address: $address');
        print('🚗 Speed: ${_currentSpeed.toStringAsFixed(1)} km/h');
      }
    } catch (e) {
      print('❌ Location error: $e');
      setState(() {
        _currentAddress = 'Unable to fetch location';
      });
    }
  }

  Future<void> _updateCurrentLocation() async {
    if (!_isTracking) return;

    final latest = await _bgLocationService.getLatestLocation();
    if (latest != null) {
      setState(() {
        _currentSpeed = (latest['speed'] as num?)?.toDouble() ?? 0.0;
      });

      final lat = latest['latitude'] as double;
      final lng = latest['longitude'] as double;
      final address =
          await _geocodingService.getAddressFromCoordinates(lat, lng);

      setState(() {
        _currentAddress = address;
      });
    }
  }

  // ============================================
  // CHECK IN/OUT
  // ============================================

  Future<void> _handleCheckIn() async {
    final allowed = await _ensureLocationEnabled();
    if (!allowed) return;

    await _getCurrentLocation();

    if (_currentPosition == null) {
      _showSnackBar('Unable to get location', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.checkIn(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _currentAddress,
      );

      setState(() {
        _isCheckedIn = true;
        _isLoading = false;
      });

      _showSnackBar('✅ Checked in successfully', AppTheme.success);

      await _startBackgroundTracking();

      await _fetchTodayStats();
      await _fetchTodayTimeline();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('❌ Check-in failed: $e', AppTheme.error);
    }
  }

  Future<void> _handleCheckOut() async {
    final allowed = await _ensureLocationEnabled();
    if (!allowed) return;

    await _getCurrentLocation();

    if (_currentPosition == null) {
      _showSnackBar('Unable to get location', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiService.checkOut(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        address: _currentAddress,
      );

      setState(() {
        _isCheckedIn = false;
        _isLoading = false;
      });

      _showSnackBar('✅ Checked out successfully', AppTheme.success);

      await _stopBackgroundTracking();

      await _fetchTodayStats();
      await _fetchTodayTimeline();
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('❌ Check-out failed: $e', AppTheme.error);
    }
  }

  Future<void> _startBackgroundTracking() async {
    final allowed = await _ensureLocationEnabled();
    if (!allowed) return;

    try {
      await _bgLocationService.start(
        userId: widget.userId,
        userName: widget.userName,
      );

      setState(() => _isTracking = true);
      print('🟢 Background tracking started');
    } catch (e) {
      print('❌ Failed to start tracking: $e');
    }
  }

  Future<void> _stopBackgroundTracking() async {
    try {
      await _bgLocationService.stop();
      setState(() => _isTracking = false);
      print('🔴 Background tracking stopped');
    } catch (e) {
      print('❌ Failed to stop tracking: $e');
    }
  }

  // ============================================
  // FETCH STATS
  // ============================================

  Future<void> _fetchTodayStats() async {
    if (_isLoadingStats) return;

    setState(() => _isLoadingStats = true);

    try {
      final stats = await _apiService.getMyStats(period: 'today');

      setState(() {
        _todayDistance = (stats['distance'] as num?)?.toDouble() ?? 0.0;
        _todayVisits = stats['visits'] as int? ?? 0;
        _todayDuration = stats['duration'] as int? ?? 0;
        _avgSpeed = (stats['avgSpeed'] as num?)?.toDouble() ?? 0.0;
        _maxSpeed = (stats['maxSpeed'] as num?)?.toDouble() ?? 0.0;
        _isLoadingStats = false;
      });

      print(
          '📊 Stats updated: ${_todayDistance.toStringAsFixed(1)}km, $_todayVisits visits');
    } catch (e) {
      print('❌ Stats error: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  // ============================================
  // FETCH TIMELINE
  // ============================================

  Future<void> _fetchTodayTimeline() async {
    try {
      final response = await _apiService.getTodayTimeline();
      final events = response['timeline'] as List? ?? [];

      setState(() {
        _todayTimeline = events.map((event) {
          return TimelineItem(
            time: event['time'] ?? '',
            title: event['title'] ?? '',
            subtitle: event['subtitle'],
            icon: _getIconForEvent(event['type']),
            color: _getColorForEvent(event['type']),
            type: _getTimelineType(event['type']),
            data: event['data'],
          );
        }).toList();
      });
    } catch (e) {
      print('❌ Timeline error: $e');
    }
  }

  IconData _getIconForEvent(String? type) {
    switch (type) {
      case 'check_in':
        return Icons.login;
      case 'check_out':
        return Icons.logout;
      case 'visit':
        return Icons.place;
      case 'moving':
        return Icons.directions_car;
      default:
        return Icons.circle;
    }
  }

  Color _getColorForEvent(String? type) {
    switch (type) {
      case 'check_in':
        return AppTheme.success;
      case 'check_out':
        return AppTheme.error;
      case 'visit':
        return AppTheme.info;
      case 'moving':
        return AppTheme.warning;
      default:
        return AppTheme.grey;
    }
  }

  TimelineItemType _getTimelineType(String? type) {
    switch (type) {
      case 'check_in':
        return TimelineItemType.checkIn;
      case 'check_out':
        return TimelineItemType.checkOut;
      case 'visit':
        return TimelineItemType.visit;
      case 'moving':
        return TimelineItemType.moving;
      default:
        return TimelineItemType.milestone;
    }
  }

  // ============================================
  // UI HELPERS
  // ============================================

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showTimelineSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.timeline, color: AppTheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Today\'s Journey',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _todayTimeline.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.route,
                                  size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'No journey data yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          controller: scrollController,
                          children: [
                            JourneyTimeline(items: _todayTimeline),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============================================
  // BUILD UI
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard'),
            Text(
              widget.userName,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          // Pending updates indicator
          if (_pendingUpdates > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulsingDotLoader(color: Colors.white, size: 8),
                      const SizedBox(width: 8),
                      Text(
                        '$_pendingUpdates',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'timeline') {
                _showTimelineSheet();
              }

              if (value == 'refresh') {
                await _loadStatus();
                await _getCurrentLocation();
                await _fetchTodayStats();
              }

              if (value == 'logout') {
                await _bgLocationService.stop();

                await Provider.of<AuthProvider>(context, listen: false)
                    .logout();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'timeline',
                child: ListTile(
                  leading: Icon(Icons.timeline),
                  title: Text('View Timeline'),
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                ),
              ),
            ],
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadStatus();
          await _getCurrentLocation();
          await _fetchTodayStats();
          await _fetchTodayTimeline();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Status Card
              _buildCurrentStatusCard(),

              const SizedBox(height: 24),

              // Check In/Out Button
              _buildCheckInOutButton(),

              const SizedBox(height: 24),

              // Today's Overview Header
              Row(
                children: [
                  Text(
                    'Today\'s Overview',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.timeline, size: 18),
                    label: const Text('Timeline'),
                    onPressed: _showTimelineSheet,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  StatCard(
                    title: 'Distance',
                    value: '${_todayDistance.toStringAsFixed(1)} km',
                    icon: Icons.straighten,
                    color: AppTheme.info,
                    subtitle: 'Traveled today',
                    isLoading: _isLoadingStats,
                  ),
                  StatCard(
                    title: 'Visits',
                    value: '$_todayVisits',
                    icon: Icons.location_on,
                    color: AppTheme.success,
                    subtitle: 'Completed',
                    isLoading: _isLoadingStats,
                  ),
                  StatCard(
                    title: 'Duration',
                    value: '${(_todayDuration / 60).toStringAsFixed(1)}h',
                    icon: Icons.access_time,
                    color: AppTheme.warning,
                    subtitle: 'On duty',
                    isLoading: _isLoadingStats,
                  ),
                  StatCard(
                    title: 'Avg Speed',
                    value: '${_avgSpeed.toStringAsFixed(0)} km/h',
                    icon: Icons.speed,
                    color: AppTheme.getSpeedColor(_avgSpeed),
                    subtitle: 'Max: ${_maxSpeed.toStringAsFixed(0)}',
                    isLoading: _isLoadingStats,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Timeline Preview
              if (_todayTimeline.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Recent Activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _showTimelineSheet,
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CompactTimeline(
                    items: _todayTimeline,
                    maxItems: 5,
                  ),
                ),
              ],

              const SizedBox(height: 80), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: _isTracking ? AppTheme.primaryGradient : null,
            color: _isTracking ? null : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _isTracking
                    ? AppTheme.primary.withOpacity(0.3 * _pulseController.value)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: _isTracking ? 5 * _pulseController.value : 0,
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isTracking
                          ? Colors.white.withOpacity(0.3)
                          : AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
                      color: _isTracking ? Colors.white : AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isTracking ? 'TRACKING ACTIVE' : 'TRACKING INACTIVE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                _isTracking ? Colors.white70 : Colors.grey[600],
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isTracking
                              ? 'GPS updates every 10 seconds'
                              : 'Check in to start tracking',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                _isTracking ? Colors.white60 : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isTracking)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.success,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white
                                      .withOpacity(_pulseController.value),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: _isTracking ? Colors.white30 : Colors.grey[200]),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.speed,
                              size: 16,
                              color: _isTracking
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Speed',
                              style: TextStyle(
                                fontSize: 11,
                                color: _isTracking
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentSpeed.toStringAsFixed(1)} km/h',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _isTracking ? Colors.white : AppTheme.dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: _isTracking
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Location',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _isTracking
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentAddress.split(',').first,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _isTracking ? Colors.white : AppTheme.dark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckInOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (_isCheckedIn ? _handleCheckOut : _handleCheckIn),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCheckedIn ? AppTheme.error : AppTheme.success,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isCheckedIn ? Icons.logout : Icons.login,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isCheckedIn ? 'CHECK OUT' : 'CHECK IN',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
