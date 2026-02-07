// lib/services/persistent_queue_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class PersistentQueueService {
  static Database? _database;
  static const String _tableName = 'location_queue';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'location_queue.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            address TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            created_at INTEGER NOT NULL
          )
        ''');
        print('📦 Database created: location_queue.db');
      },
    );
  }

  Future<void> initialize() async {
    await database;
    final count = await queueSize;
    print('📦 Queue initialized with $count pending updates');
  }

  // Add location update to queue
  Future<void> addLocationUpdate(
    double latitude,
    double longitude,
    String address,
    String timestamp,
  ) async {
    final db = await database;

    await db.insert(
      _tableName,
      {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'timestamp': timestamp,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    print('📦 Added to queue: $latitude, $longitude at $timestamp');
  }

  // Get queue size
  Future<int> get queueSize async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Check if has queued updates (async version)
  Future<bool> get hasQueuedUpdates async {
    final size = await queueSize;
    return size > 0;
  }

  // Flush queue - send all updates
  Future<void> flush(
    Future<void> Function(
            double lat, double lng, String address, String timestamp)
        sendUpdate,
  ) async {
    final db = await database;

    // Get all queued updates ordered by creation time
    final List<Map<String, dynamic>> updates = await db.query(
      _tableName,
      orderBy: 'created_at ASC',
    );

    if (updates.isEmpty) {
      print('📦 Queue is empty');
      return;
    }

    print('📦 Flushing ${updates.length} updates...');

    List<int> successfulIds = [];

    for (final update in updates) {
      try {
        await sendUpdate(
          update['latitude'] as double,
          update['longitude'] as double,
          update['address'] as String,
          update['timestamp'] as String,
        );

        successfulIds.add(update['id'] as int);
        print('✅ Sent update #${update['id']}');
      } catch (e) {
        print('❌ Failed to send update #${update['id']}: $e');
        // Stop flushing on first failure to preserve order
        break;
      }
    }

    // Remove successful updates from queue
    if (successfulIds.isNotEmpty) {
      await db.delete(
        _tableName,
        where: 'id IN (${successfulIds.join(',')})',
      );
      print('📦 Removed ${successfulIds.length} updates from queue');
    }

    final remaining = await queueSize;
    print('📦 Remaining in queue: $remaining');
  }

  // Clear all queued updates (use with caution)
  Future<void> clearQueue() async {
    final db = await database;
    await db.delete(_tableName);
    print('📦 Queue cleared');
  }

  // Get oldest update timestamp (for debugging)
  Future<String?> getOldestUpdateTime() async {
    final db = await database;
    final result = await db.query(
      _tableName,
      columns: ['timestamp'],
      orderBy: 'created_at ASC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['timestamp'] as String?;
  }

  // Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
