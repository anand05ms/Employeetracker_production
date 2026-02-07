// // lib/screens/admin/admin_employees_screen.dart
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';
// import '../../services/api_service.dart';
// import '../../services/socket_service.dart';
// import '../../models/user.dart';

// class AdminEmployeesScreen extends StatefulWidget {
//   const AdminEmployeesScreen({Key? key}) : super(key: key);

//   @override
//   State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
// }

// class _AdminEmployeesScreenState extends State<AdminEmployeesScreen>
//     with SingleTickerProviderStateMixin {
//   final ApiService _apiService = ApiService();
//   final SocketService _socketService = SocketService();
//   late TabController _tabController;

//   List<User> _allEmployees = [];
//   List<Map<String, dynamic>> _checkedInEmployees = [];
//   List<User> _notCheckedInEmployees = [];
//   List<Map<String, dynamic>> _reachedEmployees = []; // ✅ NEW: In Office
//   List<Map<String, dynamic>> _checkedOutEmployees = [];

//   bool _isLoading = true;
//   Map<String, dynamic>? _stats;
//   Timer? _refreshTimer;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 5, vsync: this);
//     // ✅ Changed from 3 to 4
//     _loadData();
//     _setupSocketConnection();
//     _startAutoRefresh();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _refreshTimer?.cancel();
//     super.dispose();
//   }

//   // 🔄 AUTO-REFRESH EVERY 5 SECONDS
//   void _startAutoRefresh() {
//     _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
//       print('🔄 Auto-refreshing employees list (every 15s)...');
//       _loadData();
//     });
//   }

//   // 📡 SOCKET CONNECTION FOR REAL-TIME UPDATES
//   Future<void> _setupSocketConnection() async {
//     try {
//       final token = await _apiService.getToken();
//       if (token != null) {
//         _socketService.connect(token);
//         _socketService.joinAdminRoom();

//         // Listen to real-time status changes
//         _socketService.socket?.on('employee_status_changed', (data) {
//           print(
//             '📍 Employee status changed: ${data['type']} - ${data['employeeName']}',
//           );
//           _loadData(); // Refresh all tabs
//         });
//       }
//     } catch (e) {
//       print('❌ Socket connection error: $e');
//     }
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);

//     try {
//       final allEmployeesFuture = _apiService.getAllEmployees();
//       final checkedInFuture = _apiService.getCheckedInEmployees();
//       final notCheckedInFuture = _apiService.getNotCheckedInEmployees();
//       final reachedFuture = _apiService.getReachedEmployees();
//       final checkedOutFuture = _apiService.getCheckedOutEmployees();
//       final statsFuture = _apiService.getDashboardStats();

//       final results = await Future.wait([
//         allEmployeesFuture,
//         checkedInFuture,
//         notCheckedInFuture,
//         reachedFuture,
//         checkedOutFuture,
//         statsFuture,
//       ]);

//       setState(() {
//         _allEmployees = results[0] as List<User>;
//         _checkedInEmployees = results[1] as List<Map<String, dynamic>>;
//         _notCheckedInEmployees = results[2] as List<User>;
//         _reachedEmployees = results[3] as List<Map<String, dynamic>>;
//         _checkedOutEmployees = results[4] as List<Map<String, dynamic>>;
//         _stats = results[5] as Map<String, dynamic>;
//         _isLoading = false;
//       });

//       print(
//         '✅ Loaded: ${_allEmployees.length} total, ${_checkedInEmployees.length} checked in, ${_reachedEmployees.length} in office',
//       );
//     } catch (e) {
//       setState(() => _isLoading = false);
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error loading data: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Stats card
//           if (_stats != null)
//             Card(
//               margin: const EdgeInsets.all(16),
//               child: Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildStatColumn(
//                       'Total',
//                       '${_stats!['totalEmployees'] ?? 0}',
//                       Icons.people,
//                       Colors.blue,
//                     ),
//                     _buildStatColumn(
//                       'Checked In',
//                       '${_stats!['checkedInToday'] ?? 0}',
//                       Icons.check_circle,
//                       Colors.green,
//                     ),
//                     _buildStatColumn(
//                       'Not Checked In',
//                       '${_stats!['notCheckedIn'] ?? 0}',
//                       Icons.pending,
//                       Colors.orange,
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//           // Tabs - ✅ NOW 4 TABS
//           TabBar(
//             controller: _tabController,
//             labelColor: Theme.of(context).primaryColor,
//             unselectedLabelColor: Colors.grey,
//             indicatorColor: Theme.of(context).primaryColor,
//             isScrollable: true, // ✅ Make tabs scrollable for 4 tabs
//             tabs: [
//               Tab(
//                 text: 'All (${_allEmployees.length})',
//                 icon: const Icon(Icons.people),
//               ),
//               Tab(
//                 text: 'Checked In (${_checkedInEmployees.length})',
//                 icon: const Icon(Icons.directions_walk),
//               ),
//               Tab(
//                 text: 'Not Checked In Today (${_notCheckedInEmployees.length})',
//                 icon: const Icon(Icons.pending),
//               ),
//               Tab(
//                 text: 'In Office (${_reachedEmployees.length})',
//                 icon: const Icon(Icons.business),
//               ),
//               Tab(
//                 text: 'Checked Out (${_checkedOutEmployees.length})', // ✅ NEW
//                 icon: const Icon(Icons.logout),
//               ),
//             ],
//           ),

//           // Tab views - ✅ NOW 4 TAB VIEWS
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : TabBarView(
//                     controller: _tabController,
//                     children: [
//                       _buildAllEmployeesList(),
//                       _buildCheckedInEmployeesList(),
//                       _buildNotCheckedInEmployeesList(),
//                       _buildInOfficeEmployeesList(),
//                       _buildCheckedOutEmployeesList(), // ✅ NEW
//                     ],
//                   ),
//           ),
//         ],
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _loadData,
//         child: const Icon(Icons.refresh),
//       ),
//     );
//   }

//   Widget _buildStatColumn(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Column(
//       children: [
//         Icon(icon, color: color, size: 32),
//         const SizedBox(height: 8),
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
//       ],
//     );
//   }

//   Widget _buildAllEmployeesList() {
//     if (_allEmployees.isEmpty) {
//       return const Center(child: Text('No employees found'));
//     }

//     return RefreshIndicator(
//       onRefresh: _loadData,
//       child: ListView.builder(
//         itemCount: _allEmployees.length,
//         itemBuilder: (context, index) {
//           final employee = _allEmployees[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.blue,
//                 child: Text(
//                   employee.name[0].toUpperCase(),
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//               title: Text(
//                 employee.name,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (employee.employeeId != null)
//                     Text('ID: ${employee.employeeId}'),
//                   if (employee.department != null) Text(employee.department!),
//                   if (employee.phone != null) Text(employee.phone!),
//                 ],
//               ),
//               trailing: Icon(
//                 employee.isActive ? Icons.check_circle : Icons.cancel,
//                 color: employee.isActive ? Colors.green : Colors.red,
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCheckedInEmployeesList() {
//     if (_checkedInEmployees.isEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.info_outline, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               'No employees checked in today',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadData,
//       child: ListView.builder(
//         itemCount: _checkedInEmployees.length,
//         itemBuilder: (context, index) {
//           final data = _checkedInEmployees[index];
//           final employee = data['employee'];
//           final attendance = data['attendance'];
//           final location = data['location'];

//           final checkInTime = DateTime.parse(attendance['checkInTime']);

//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.blue,
//                 child: Text(
//                   employee['name'][0].toUpperCase(),
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//               title: Text(
//                 employee['name'],
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       const Icon(Icons.access_time, size: 16),
//                       const SizedBox(width: 4),
//                       Text(
//                         'Checked in: ${DateFormat('hh:mm a').format(checkInTime.toLocal())}',
//                         style: const TextStyle(fontWeight: FontWeight.w500),
//                       ),
//                     ],
//                   ),
//                   if (attendance['checkInAddress'] != null) ...[
//                     const SizedBox(height: 2),
//                     Row(
//                       children: [
//                         const Icon(Icons.location_on, size: 16),
//                         const SizedBox(width: 4),
//                         Expanded(
//                           child: Text(
//                             attendance['checkInAddress'],
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                   if (attendance['distanceFromOffice'] != null) ...[
//                     const SizedBox(height: 2),
//                     Text(
//                       'Distance: ${(attendance['distanceFromOffice'] / 1000).toStringAsFixed(1)} km',
//                       style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                     ),
//                   ],
//                 ],
//               ),
//               trailing: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.blue[100],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       'On the way',
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue[900],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildNotCheckedInEmployeesList() {
//     if (_notCheckedInEmployees.isEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.celebration, size: 64, color: Colors.green),
//             SizedBox(height: 16),
//             Text(
//               'All employees checked in!',
//               style: TextStyle(fontSize: 16, color: Colors.green),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadData,
//       child: ListView.builder(
//         itemCount: _notCheckedInEmployees.length,
//         itemBuilder: (context, index) {
//           final employee = _notCheckedInEmployees[index];
//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.grey,
//                 child: Text(
//                   employee.name[0].toUpperCase(),
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//               title: Text(
//                 employee.name,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (employee.employeeId != null)
//                     Text('ID: ${employee.employeeId}'),
//                   if (employee.department != null) Text(employee.department!),
//                 ],
//               ),
//               trailing: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.red[100],
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   'Absent',
//                   style: TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.red[900],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   // ✅ NEW: BUILD IN OFFICE EMPLOYEES LIST
//   Widget _buildInOfficeEmployeesList() {
//     if (_reachedEmployees.isEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.business_outlined, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               'No employees in office yet',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadData,
//       child: ListView.builder(
//         itemCount: _reachedEmployees.length,
//         itemBuilder: (context, index) {
//           final data = _reachedEmployees[index];
//           final employee = data['employee'];
//           final attendance = data['attendance'];

//           final checkInTime = attendance['checkInTime'] != null
//               ? DateTime.parse(attendance['checkInTime'])
//               : null;

//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             elevation: 2,
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.green,
//                 child: Text(
//                   employee['name'][0].toUpperCase(),
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ),
//               title: Text(
//                 employee['name'],
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (employee['employeeId'] != null) ...[
//                     const SizedBox(height: 4),
//                     Text('ID: ${employee['employeeId']}'),
//                   ],
//                   if (employee['department'] != null)
//                     Text(employee['department']),
//                   if (checkInTime != null) ...[
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         const Icon(
//                           Icons.access_time,
//                           size: 16,
//                           color: Colors.green,
//                         ),
//                         const SizedBox(width: 4),
//                         Text(
//                           'Arrived: ${DateFormat('hh:mm a').format(checkInTime.toLocal())}',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w500,
//                             color: Colors.green[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ],
//               ),
//               trailing: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(Icons.check_circle, color: Colors.green[700], size: 28),
//                   const SizedBox(height: 4),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 8,
//                       vertical: 4,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.green[100],
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       'In Office',
//                       style: TextStyle(
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green[900],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCheckedOutEmployeesList() {
//     if (_checkedOutEmployees.isEmpty) {
//       return const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.logout, size: 64, color: Colors.grey),
//             SizedBox(height: 16),
//             Text(
//               'No employees checked out yet',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _loadData,
//       child: ListView.builder(
//         itemCount: _checkedOutEmployees.length,
//         itemBuilder: (context, index) {
//           final data = _checkedOutEmployees[index];
//           final employee = data['employee'];
//           final attendance = data['attendance'];

//           return Card(
//             margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ListTile(
//               leading: CircleAvatar(
//                 backgroundColor: Colors.red,
//                 child: Text(
//                   employee['name'][0].toUpperCase(),
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//               title: Text(
//                 employee['name'],
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text('Total Hours: ${attendance['totalHours']}'),
//               trailing: const Icon(Icons.check, color: Colors.red),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// /* lib/screens/admin/admin_employees_screen.dart*/
// import 'employee_route_replay_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'dart:async';
// import '../../services/api_service.dart';
// import '../../services/socket_service.dart';
// import '../../models/user.dart';

// class AdminEmployeesScreen extends StatefulWidget {
//   const AdminEmployeesScreen({Key? key}) : super(key: key);

//   @override
//   State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
// }

// class _AdminEmployeesScreenState extends State<AdminEmployeesScreen>
//     with SingleTickerProviderStateMixin {
//   final ApiService _apiService = ApiService();
//   final SocketService _socketService = SocketService();

//   late TabController _tabController;

//   List<User> _allEmployees = [];
//   List<Map<String, dynamic>> _checkedInEmployees = [];
//   List<User> _notCheckedInEmployees = [];
//   List<Map<String, dynamic>> _reachedEmployees = [];
//   List<Map<String, dynamic>> _checkedOutEmployees = [];

//   bool _isLoading = true;
//   Timer? _refreshTimer;

//   // =========================================================
//   // INIT
//   // =========================================================

//   @override
//   void initState() {
//     super.initState();

//     _tabController = TabController(length: 5, vsync: this);

//     _loadData();
//     _setupSocket();
//     _startAutoRefresh();
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _refreshTimer?.cancel();
//     _socketService.disconnect();
//     super.dispose();
//   }

//   // =========================================================
//   // AUTO REFRESH
//   // =========================================================

//   void _startAutoRefresh() {
//     _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
//       _loadData();
//     });
//   }

//   // =========================================================
//   // SOCKET
//   // =========================================================

//   Future<void> _setupSocket() async {
//     final token = await _apiService.getToken();

//     if (token != null) {
//       _socketService.connect(token);
//       _socketService.joinAdminRoom();

//       _socketService.socket?.on('employee_status_changed', (_) {
//         _loadData();
//       });
//     }
//   }

//   // =========================================================
//   // LOAD DATA
//   // =========================================================

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);

//     try {
//       final results = await Future.wait([
//         _apiService.getAllEmployees(),
//         _apiService.getCheckedInEmployees(),
//         _apiService.getNotCheckedInEmployees(),
//         _apiService.getReachedEmployees(),
//         _apiService.getCheckedOutEmployees(),
//       ]);

//       setState(() {
//         _allEmployees = results[0] as List<User>;
//         _checkedInEmployees = results[1] as List<Map<String, dynamic>>;
//         _notCheckedInEmployees = results[2] as List<User>;
//         _reachedEmployees = results[3] as List<Map<String, dynamic>>;
//         _checkedOutEmployees = results[4] as List<Map<String, dynamic>>;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error loading: $e')));
//     }
//   }

//   // =========================================================
//   // ⭐ UNIVERSAL REPLAY BUTTON (MAIN LOGIC)
//   // =========================================================

//   Widget _replayButton(String employeeId) {
//     return IconButton(
//       icon: const Icon(Icons.route, color: Colors.blue),
//       tooltip: "Replay route",
//       onPressed: () async {
//         try {
//           final date = DateTime.now().toIso8601String().split("T")[0];

//           final res = await _apiService.getEmployeeRoute(employeeId, date);

//           final route = res["data"]["route"];

//           // ⭐ No movement
//           if (route == null || route.isEmpty) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(
//                 content: Text("No movement data for this employee today"),
//                 backgroundColor: Colors.orange,
//               ),
//             );
//             return;
//           }

//           // ⭐ Open replay screen
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => EmployeeRouteReplayScreen(
//                 employeeId: employeeId,
//                 date: date,
//               ),
//             ),
//           );
//         } catch (e) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text("Error loading route: $e")),
//           );
//         }
//       },
//     );
//   }

//   // =========================================================
//   // COMMON CARD
//   // =========================================================

//   Widget _employeeCard({
//     required String name,
//     required String subtitle,
//     required Color color,
//     required String id,
//   }) {
//     return Card(
//       margin: const EdgeInsets.all(8),
//       child: ListTile(
//         leading: CircleAvatar(
//           backgroundColor: color,
//           child: Text(
//             name[0].toUpperCase(),
//             style: const TextStyle(color: Colors.white),
//           ),
//         ),
//         title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(subtitle),

//         // ⭐ ALWAYS SHOW REPLAY
//         trailing: _replayButton(id),
//       ),
//     );
//   }

//   // =========================================================
//   // UI
//   // =========================================================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           TabBar(
//             controller: _tabController,
//             isScrollable: true,
//             labelColor: Theme.of(context).primaryColor,
//             tabs: [
//               Tab(
//                   text: 'All (${_allEmployees.length})',
//                   icon: Icon(Icons.people)),
//               Tab(
//                   text: 'Checked In (${_checkedInEmployees.length})',
//                   icon: Icon(Icons.directions_walk)),
//               Tab(
//                   text: 'Not Checked In (${_notCheckedInEmployees.length})',
//                   icon: Icon(Icons.pending)),
//               Tab(
//                   text: 'In Office (${_reachedEmployees.length})',
//                   icon: Icon(Icons.business)),
//               Tab(
//                   text: 'Checked Out (${_checkedOutEmployees.length})',
//                   icon: Icon(Icons.logout)),
//             ],
//           ),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : TabBarView(
//                     controller: _tabController,
//                     children: [
//                       _allTab(),
//                       _checkedInTab(),
//                       _notCheckedInTab(),
//                       _inOfficeTab(),
//                       _checkedOutTab(),
//                     ],
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   // =========================================================
//   // TABS
//   // =========================================================

//   Widget _allTab() {
//     return ListView.builder(
//       itemCount: _allEmployees.length,
//       itemBuilder: (_, i) {
//         final e = _allEmployees[i];
//         return _employeeCard(
//           name: e.name,
//           subtitle: e.department ?? '',
//           color: e.isActive ? Colors.green : Colors.red,
//           id: e.id,
//         );
//       },
//     );
//   }

//   Widget _checkedInTab() {
//     if (_checkedInEmployees.isEmpty) return _empty("No employees checked in");

//     return ListView.builder(
//       itemCount: _checkedInEmployees.length,
//       itemBuilder: (_, i) {
//         final d = _checkedInEmployees[i];
//         final emp = d['employee'];
//         final att = d['attendance'];

//         final time = DateTime.parse(att['checkInTime']);

//         return _employeeCard(
//           name: emp['name'],
//           subtitle: 'Checked in at ${DateFormat('hh:mm a').format(time)}',
//           color: Colors.blue,
//           id: emp['_id'],
//         );
//       },
//     );
//   }

//   Widget _notCheckedInTab() {
//     if (_notCheckedInEmployees.isEmpty) return _empty("Everyone checked in");

//     return ListView.builder(
//       itemCount: _notCheckedInEmployees.length,
//       itemBuilder: (_, i) {
//         final e = _notCheckedInEmployees[i];

//         return _employeeCard(
//           name: e.name,
//           subtitle: 'Absent',
//           color: Colors.red,
//           id: e.id,
//         );
//       },
//     );
//   }

//   Widget _inOfficeTab() {
//     if (_reachedEmployees.isEmpty) return _empty("No one in office");

//     return ListView.builder(
//       itemCount: _reachedEmployees.length,
//       itemBuilder: (_, i) {
//         final d = _reachedEmployees[i];
//         final emp = d['employee'];

//         return _employeeCard(
//           name: emp['name'],
//           subtitle: 'In Office',
//           color: Colors.green,
//           id: emp['_id'],
//         );
//       },
//     );
//   }

//   Widget _checkedOutTab() {
//     if (_checkedOutEmployees.isEmpty) return _empty("No one checked out");

//     return ListView.builder(
//       itemCount: _checkedOutEmployees.length,
//       itemBuilder: (_, i) {
//         final d = _checkedOutEmployees[i];
//         final emp = d['employee'];
//         final att = d['attendance'];

//         return _employeeCard(
//           name: emp['name'],
//           subtitle: 'Hours: ${att['totalHours']}',
//           color: Colors.orange,
//           id: emp['_id'],
//         );
//       },
//     );
//   }

//   // =========================================================

//   Widget _empty(String text) {
//     return Center(
//       child:
//           Text(text, style: const TextStyle(color: Colors.grey, fontSize: 16)),
//     );
//   }
// }

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// import '../../models/user.dart';
// import '../../services/api_service.dart';
// import '../../services/socket_service.dart';
// import 'employee_route_replay_screen.dart';

// class AdminEmployeesScreen extends StatefulWidget {
//   const AdminEmployeesScreen({Key? key}) : super(key: key);

//   @override
//   State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
// }

// class _AdminEmployeesScreenState extends State<AdminEmployeesScreen>
//     with SingleTickerProviderStateMixin {
//   final ApiService _apiService = ApiService();
//   final SocketService _socketService = SocketService();

//   late TabController _tabController;
//   Timer? _refreshTimer;

//   bool _isLoading = true;

//   List<User> _allEmployees = [];
//   List<Map<String, dynamic>> _checkedInEmployees = [];
//   List<User> _notCheckedInEmployees = [];
//   List<Map<String, dynamic>> _reachedEmployees = [];
//   List<Map<String, dynamic>> _checkedOutEmployees = [];

//   // ================= INIT =================

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 5, vsync: this);
//     _loadData();
//     _setupSocket();
//     _startAutoRefresh();
//   }

//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     _socketService.disconnect();
//     _tabController.dispose();
//     super.dispose();
//   }

//   // ================= DATA =================

//   void _startAutoRefresh() {
//     _refreshTimer =
//         Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
//   }

//   Future<void> _setupSocket() async {
//     final token = await _apiService.getToken();
//     if (token == null) return;

//     _socketService.connect(token);
//     _socketService.joinAdminRoom();
//     _socketService.socket?.on(
//       'employee_status_changed',
//       (_) => _loadData(),
//     );
//   }

//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);

//     try {
//       final results = await Future.wait([
//         _apiService.getAllEmployees(),
//         _apiService.getCheckedInEmployees(),
//         _apiService.getNotCheckedInEmployees(),
//         _apiService.getReachedEmployees(),
//         _apiService.getCheckedOutEmployees(),
//       ]);

//       setState(() {
//         _allEmployees = results[0] as List<User>;
//         _checkedInEmployees = results[1] as List<Map<String, dynamic>>;
//         _notCheckedInEmployees = results[2] as List<User>;
//         _reachedEmployees = results[3] as List<Map<String, dynamic>>;
//         _checkedOutEmployees = results[4] as List<Map<String, dynamic>>;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load data: $e')),
//       );
//     }
//   }

//   // ================= REPLAY UI =================

//   void _showReplayOptions(String employeeId) {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _replayTile("Today", 0, employeeId),
//             _replayTile("Yesterday", 1, employeeId),
//             _replayTile("2 Days Ago", 2, employeeId),
//             ListTile(
//               leading: const Icon(Icons.calendar_today),
//               title: const Text("Pick a date"),
//               onTap: () async {
//                 final picked = await showDatePicker(
//                   context: context,
//                   firstDate: DateTime.now().subtract(const Duration(days: 30)),
//                   lastDate: DateTime.now(),
//                   initialDate: DateTime.now(),
//                 );

//                 if (picked != null) {
//                   Navigator.pop(context);
//                   _openReplay(employeeId, picked);
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _replayTile(String label, int daysAgo, String id) {
//     return ListTile(
//       leading: const Icon(Icons.play_arrow),
//       title: Text(label),
//       onTap: () {
//         Navigator.pop(context);
//         final date = DateTime.now().subtract(Duration(days: daysAgo));
//         _openReplay(id, date);
//       },
//     );
//   }

//   Future<void> _openReplay(String employeeId, DateTime date) async {
//     final d = DateFormat('yyyy-MM-dd').format(date);

//     try {
//       final res = await _apiService.getEmployeeRoute(employeeId, d);
//       final route = res["data"]["route"];

//       if (route == null || route.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text("No movement data on $d"),
//             backgroundColor: Colors.orange,
//           ),
//         );
//         return;
//       }

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => EmployeeRouteReplayScreen(
//             employeeId: employeeId,
//             date: d,
//           ),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Replay failed: $e")),
//       );
//     }
//   }

//   // ================= CARD =================

//   Widget _employeeCard({
//     required String name,
//     required String subtitle,
//     required Color color,
//     required String id,
//   }) {
//     return InkWell(
//       onTap: () => _showReplayOptions(id), // 👈 MOBILE FIRST
//       child: Card(
//         margin: const EdgeInsets.all(8),
//         child: ListTile(
//           leading: CircleAvatar(
//             backgroundColor: color,
//             child: Text(
//               name[0].toUpperCase(),
//               style: const TextStyle(color: Colors.white),
//             ),
//           ),
//           title:
//               Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
//           subtitle: Text(subtitle),
//           trailing: const Icon(Icons.chevron_right), // visual hint
//         ),
//       ),
//     );
//   }

//   // ================= UI =================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           TabBar(
//             controller: _tabController,
//             isScrollable: true,
//             tabs: [
//               Tab(text: 'All (${_allEmployees.length})'),
//               Tab(text: 'Checked In (${_checkedInEmployees.length})'),
//               Tab(text: 'Not Checked In (${_notCheckedInEmployees.length})'),
//               Tab(text: 'In Office (${_reachedEmployees.length})'),
//               Tab(text: 'Checked Out (${_checkedOutEmployees.length})'),
//             ],
//           ),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : TabBarView(
//                     controller: _tabController,
//                     children: [
//                       _allTab(),
//                       _checkedInTab(),
//                       _notCheckedInTab(),
//                       _inOfficeTab(),
//                       _checkedOutTab(),
//                     ],
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= TABS =================

//   Widget _allTab() => ListView.builder(
//         itemCount: _allEmployees.length,
//         itemBuilder: (_, i) {
//           final e = _allEmployees[i];
//           return _employeeCard(
//             name: e.name,
//             subtitle: e.department ?? '',
//             color: e.isActive ? Colors.green : Colors.red,
//             id: e.id,
//           );
//         },
//       );

//   Widget _checkedInTab() => _checkedInEmployees.isEmpty
//       ? _empty("No employees checked in")
//       : ListView.builder(
//           itemCount: _checkedInEmployees.length,
//           itemBuilder: (_, i) {
//             final d = _checkedInEmployees[i];
//             final emp = d['employee'];
//             final att = d['attendance'];
//             final time = DateTime.parse(att['checkInTime']);

//             return _employeeCard(
//               name: emp['name'],
//               subtitle: 'Checked in at ${DateFormat('hh:mm a').format(time)}',
//               color: Colors.blue,
//               id: emp['_id'],
//             );
//           },
//         );

//   Widget _notCheckedInTab() => _notCheckedInEmployees.isEmpty
//       ? _empty("Everyone checked in")
//       : ListView.builder(
//           itemCount: _notCheckedInEmployees.length,
//           itemBuilder: (_, i) {
//             final e = _notCheckedInEmployees[i];
//             return _employeeCard(
//               name: e.name,
//               subtitle: 'Not checked in',
//               color: Colors.red,
//               id: e.id,
//             );
//           },
//         );

//   Widget _inOfficeTab() => _reachedEmployees.isEmpty
//       ? _empty("No one in office")
//       : ListView.builder(
//           itemCount: _reachedEmployees.length,
//           itemBuilder: (_, i) {
//             final emp = _reachedEmployees[i]['employee'];
//             return _employeeCard(
//               name: emp['name'],
//               subtitle: 'In Office',
//               color: Colors.green,
//               id: emp['_id'],
//             );
//           },
//         );

//   Widget _checkedOutTab() => _checkedOutEmployees.isEmpty
//       ? _empty("No one checked out")
//       : ListView.builder(
//           itemCount: _checkedOutEmployees.length,
//           itemBuilder: (_, i) {
//             final d = _checkedOutEmployees[i];
//             final emp = d['employee'];
//             final att = d['attendance'];

//             return _employeeCard(
//               name: emp['name'],
//               subtitle: 'Hours: ${att['totalHours']}',
//               color: Colors.orange,
//               id: emp['_id'],
//             );
//           },
//         );

//   Widget _empty(String text) => Center(
//         child: Text(text,
//             style: const TextStyle(color: Colors.grey, fontSize: 16)),
//       );
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import 'employee_route_replay_screen.dart';

class AdminEmployeesScreen extends StatefulWidget {
  const AdminEmployeesScreen({Key? key}) : super(key: key);

  @override
  State<AdminEmployeesScreen> createState() => _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends State<AdminEmployeesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final SocketService _socketService = SocketService();

  late TabController _tabController;
  Timer? _refreshTimer;

  bool _isLoading = true;

  List<User> _allEmployees = [];
  List<Map<String, dynamic>> _checkedInEmployees = [];
  List<User> _notCheckedInEmployees = [];
  List<Map<String, dynamic>> _reachedEmployees = [];
  List<Map<String, dynamic>> _checkedOutEmployees = [];

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
    _setupSocket();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _socketService.disconnect();
    _tabController.dispose();
    super.dispose();
  }

  // ================= DATA =================

  void _startAutoRefresh() {
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
  }

  Future<void> _setupSocket() async {
    final token = await _apiService.getToken();
    if (token == null) return;

    _socketService.connect(token);
    _socketService.joinAdminRoom();
    _socketService.socket?.on(
      'employee_status_changed',
      (_) => _loadData(),
    );
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.getAllEmployees(),
        _apiService.getCheckedInEmployees(),
        _apiService.getNotCheckedInEmployees(),
        _apiService.getReachedEmployees(),
        _apiService.getCheckedOutEmployees(),
      ]);

      setState(() {
        _allEmployees = results[0] as List<User>;
        _checkedInEmployees = results[1] as List<Map<String, dynamic>>;
        _notCheckedInEmployees = results[2] as List<User>;
        _reachedEmployees = results[3] as List<Map<String, dynamic>>;
        _checkedOutEmployees = results[4] as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data: $e')),
      );
    }
  }

  // ================= REPLAY UI =================

  void _showReplayOptions(String employeeId, String employeeName) {
    print("🎬 Opening replay options for employee: $employeeId");

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'View Route Replay - $employeeName',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(),

              // Date options
              _replayTile("Today", 0, employeeId),
              _replayTile("Yesterday", 1, employeeId),
              _replayTile("2 Days Ago", 2, employeeId),

              const Divider(),

              // Custom date picker
              ListTile(
                leading: const Icon(Icons.calendar_today, color: Colors.blue),
                title: const Text("Pick a custom date"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                    initialDate: DateTime.now(),
                  );

                  if (picked != null && mounted) {
                    Navigator.pop(context);
                    _openReplay(employeeId, picked);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _replayTile(String label, int daysAgo, String id) {
    return ListTile(
      leading: const Icon(Icons.play_circle, color: Colors.green),
      title: Text(label),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.pop(context);
        final date = DateTime.now().subtract(Duration(days: daysAgo));
        _openReplay(id, date);
      },
    );
  }

  Future<void> _openReplay(String employeeId, DateTime date) async {
    final d = DateFormat('yyyy-MM-dd').format(date);

    print("🔍 Fetching route for employee: $employeeId on date: $d");

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final res = await _apiService.getEmployeeRoute(employeeId, d);

      print("📡 Route response: $res");

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      final route = res["data"]?["route"];

      if (route == null || route.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No movement data available for $d"),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      print("✅ Route has ${route.length} points");

      // Navigate to replay screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EmployeeRouteReplayScreen(
            employeeId: employeeId,
            date: d,
          ),
        ),
      );
    } catch (e, stackTrace) {
      print("❌ Replay error: $e");
      print("Stack trace: $stackTrace");

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load route: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  // ================= CARD =================

  Widget _employeeCard({
    required String name,
    required String subtitle,
    required Color color,
    required String id,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        // Make the entire tile tappable
        onTap: () {
          print("👆 Tapped on employee: $name (ID: $id)");
          _showReplayOptions(id, name);
        },
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Route replay button
            IconButton(
              icon: const Icon(Icons.route, color: Colors.blue),
              tooltip: 'View route replay',
              onPressed: () {
                print("🗺️ Route button pressed for: $name");
                _showReplayOptions(id, name);
              },
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(text: 'All (${_allEmployees.length})'),
              Tab(text: 'Checked In (${_checkedInEmployees.length})'),
              Tab(text: 'Not Checked In (${_notCheckedInEmployees.length})'),
              Tab(text: 'In Office (${_reachedEmployees.length})'),
              Tab(text: 'Checked Out (${_checkedOutEmployees.length})'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _allTab(),
                      _checkedInTab(),
                      _notCheckedInTab(),
                      _inOfficeTab(),
                      _checkedOutTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // ================= TABS =================

  Widget _allTab() => _allEmployees.isEmpty
      ? _empty("No employees found")
      : ListView.builder(
          itemCount: _allEmployees.length,
          itemBuilder: (_, i) {
            final e = _allEmployees[i];
            return _employeeCard(
              name: e.name,
              subtitle: e.department ?? 'No department',
              color: e.isActive ? Colors.green : Colors.red,
              id: e.id,
            );
          },
        );

  Widget _checkedInTab() => _checkedInEmployees.isEmpty
      ? _empty("No employees checked in")
      : ListView.builder(
          itemCount: _checkedInEmployees.length,
          itemBuilder: (_, i) {
            final d = _checkedInEmployees[i];
            final emp = d['employee'];
            final att = d['attendance'];
            final time = DateTime.parse(att['checkInTime']);

            return _employeeCard(
              name: emp['name'] ?? 'Unknown',
              subtitle: 'Checked in at ${DateFormat('hh:mm a').format(time)}',
              color: Colors.blue,
              id: emp['_id'],
            );
          },
        );

  Widget _notCheckedInTab() => _notCheckedInEmployees.isEmpty
      ? _empty("Everyone checked in")
      : ListView.builder(
          itemCount: _notCheckedInEmployees.length,
          itemBuilder: (_, i) {
            final e = _notCheckedInEmployees[i];
            return _employeeCard(
              name: e.name,
              subtitle: 'Not checked in',
              color: Colors.red,
              id: e.id,
            );
          },
        );

  Widget _inOfficeTab() => _reachedEmployees.isEmpty
      ? _empty("No one in office")
      : ListView.builder(
          itemCount: _reachedEmployees.length,
          itemBuilder: (_, i) {
            final emp = _reachedEmployees[i]['employee'];
            return _employeeCard(
              name: emp['name'] ?? 'Unknown',
              subtitle: 'In Office',
              color: Colors.green,
              id: emp['_id'],
            );
          },
        );

  Widget _checkedOutTab() => _checkedOutEmployees.isEmpty
      ? _empty("No one checked out")
      : ListView.builder(
          itemCount: _checkedOutEmployees.length,
          itemBuilder: (_, i) {
            final d = _checkedOutEmployees[i];
            final emp = d['employee'];
            final att = d['attendance'];

            return _employeeCard(
              name: emp['name'] ?? 'Unknown',
              subtitle: 'Hours: ${att['totalHours'] ?? 'N/A'}',
              color: Colors.orange,
              id: emp['_id'],
            );
          },
        );

  Widget _empty(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}
