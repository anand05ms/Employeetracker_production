import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

class SocketService {
  // ===============================
  // SINGLETON
  // ===============================
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // ===============================
  // STATE
  // ===============================
  IO.Socket? _socket;
  bool _isConnected = false;

  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  String? _lastToken;
  String? _employeeId;
  bool _isAdmin = false;

  // ===============================
  // CONFIG
  // ===============================
  static const String _baseUrl = 'https://emptracker-backend.onrender.com';

  // ===============================
  // GETTERS (IMPORTANT)
  // ===============================
  bool get isConnected => _isConnected;
  IO.Socket? get socket => _socket; // 🔑 REQUIRED FOR ADMIN SCREENS

  // ===============================
  // CONNECT
  // ===============================
  void connect(String token) {
    _lastToken = token;

    print('🔌 Connecting to Socket.IO: $_baseUrl');

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setExtraHeaders({
            'Authorization': 'Bearer $token',
          })
          .build(),
    );

    _setupListeners();
    _socket!.connect();
  }

  void _setupListeners() {
    _socket?.onConnect((_) {
      print('🟢 Socket connected');
      _isConnected = true;
      _reconnectAttempts = 0;
      _cancelReconnectTimer();

      // Rejoin correct room after reconnect
      if (_isAdmin) {
        joinAdminRoom();
      } else if (_employeeId != null) {
        joinEmployeeRoom(_employeeId!);
      }
    });

    _socket?.onDisconnect((_) {
      print('🔴 Socket disconnected');
      _isConnected = false;
      _attemptReconnect();
    });

    _socket?.onConnectError((err) {
      print('❌ Socket connect error: $err');
      _isConnected = false;
      _attemptReconnect();
    });

    _socket?.onError((err) {
      print('❌ Socket error: $err');
    });
  }

  // ===============================
  // ROOMS (MATCHES server.js)
  // ===============================
  void joinEmployeeRoom(String employeeId) {
    _employeeId = employeeId;
    _isAdmin = false;

    if (_isConnected) {
      _socket?.emit('join_employee', {
        'employeeId': employeeId,
      });
      print('👤 Joined employee room: $employeeId');
    }
  }

  void joinAdminRoom() {
    _isAdmin = true;
    _employeeId = null;

    if (_isConnected) {
      _socket?.emit('join_admin');
      print('👨‍💼 Joined admin room');
    }
  }

  // ===============================
  // RECONNECT LOGIC
  // ===============================
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('⚠️ Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts);

    print(
        '🔄 Will attempt reconnect in ${delay.inSeconds}s (attempt $_reconnectAttempts)');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_isConnected && _lastToken != null) {
        disconnect();
        connect(_lastToken!);
      }
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  // ===============================
  // FORCE RECONNECT (USED BY UI)
  // ===============================
  void forceReconnect() {
    print('🔄 Forcing socket reconnection...');
    disconnect();

    if (_lastToken != null) {
      connect(_lastToken!);
    }
  }

  // ===============================
  // DISCONNECT
  // ===============================
  void disconnect() {
    print('🔌 Disconnecting Socket.IO...');
    _cancelReconnectTimer();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
