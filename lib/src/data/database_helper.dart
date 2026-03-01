import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper();

  static const _dbName = 'daily_tracker.db';
  static const _dbVersion = 4;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    final dbPath = kIsWeb ? '' : await getDatabasesPath();
    _database = await openDatabase(
      kIsWeb ? _dbName : p.join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    return _database!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        polarity TEXT NOT NULL DEFAULT 'do_more',
        window_days INTEGER NOT NULL DEFAULT 7,
        target_successes INTEGER NOT NULL DEFAULT 7,
        is_predefined INTEGER NOT NULL,
        is_active INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        activity_id INTEGER NOT NULL,
        date_key TEXT NOT NULL,
        binary_value INTEGER,
        scale_value INTEGER,
        updated_at TEXT NOT NULL,
        FOREIGN KEY(activity_id) REFERENCES activities(id),
        UNIQUE(activity_id, date_key)
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_daily_entries_activity_date ON daily_entries(activity_id, date_key)',
    );
    await db.execute('CREATE INDEX idx_daily_entries_date ON daily_entries(date_key)');

    await _applyDefaultActivities(db);
    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE activities ADD COLUMN polarity TEXT NOT NULL DEFAULT 'do_more'");
      await db.execute('ALTER TABLE activities ADD COLUMN window_days INTEGER NOT NULL DEFAULT 7');
      await db.execute('ALTER TABLE activities ADD COLUMN target_successes INTEGER NOT NULL DEFAULT 7');
      await db.execute('ALTER TABLE activities ADD COLUMN deleted_at TEXT');

      await db.execute('''
        UPDATE activities
        SET name = 'Quality Sleep'
        WHERE LOWER(name) IN ('slept well', 'sleep quality')
      ''');

      await db.execute('''
        UPDATE activities
        SET polarity = 'do_more', window_days = 7, target_successes = 7
        WHERE polarity IS NULL OR polarity = ''
      ''');
    }

    if (oldVersion < 3) {
      await db.execute('''
        UPDATE activities
        SET target_successes = 4, window_days = 7, polarity = 'do_more'
        WHERE LOWER(name) = 'workout' AND deleted_at IS NULL
      ''');
    }

    if (oldVersion < 4) {
      await _applyDefaultActivities(db);
    }
  }

  Future<void> _applyDefaultActivities(Database db) async {
    final now = DateTime.now().toIso8601String();
    const defaults = [
      {'name': 'Stretching/Mobility', 'polarity': 'do_more'},
      {'name': 'Workout', 'polarity': 'do_more'},
      {'name': 'Meditation', 'polarity': 'do_more'},
      {'name': 'Hydration', 'polarity': 'do_more'},
      {'name': 'Walk', 'polarity': 'do_more'},
      {'name': 'Eating Healthy', 'polarity': 'do_more'},
    ];

    final defaultNamesLower = defaults.map((item) => (item['name'] as String).toLowerCase()).toSet();

    final existingDefaults = await db.query(
      'activities',
      columns: ['id', 'name'],
      where: 'is_predefined = 1 AND deleted_at IS NULL',
    );

    for (final row in existingDefaults) {
      final id = row['id'] as int;
      final name = (row['name'] as String).toLowerCase();
      if (!defaultNamesLower.contains(name)) {
        await db.update(
          'activities',
          {
            'is_active': 0,
            'deleted_at': now,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    }

    for (final item in defaults) {
      final name = item['name'] as String;
      final polarity = item['polarity'] as String;
      final existing = await db.query(
        'activities',
        columns: ['id'],
        where: 'LOWER(name) = LOWER(?) AND deleted_at IS NULL',
        whereArgs: [name],
        limit: 1,
      );

      if (existing.isEmpty) {
        await db.insert('activities', {
          'name': name,
          'type': 'yes_no',
          'polarity': polarity,
          'window_days': 7,
          'target_successes': 3,
          'is_predefined': 1,
          'is_active': 1,
          'created_at': now,
          'deleted_at': null,
        });
      } else {
        await db.update(
          'activities',
          {
            'type': 'yes_no',
            'polarity': polarity,
            'window_days': 7,
            'target_successes': 3,
            'is_predefined': 1,
            'is_active': 1,
            'deleted_at': null,
          },
          where: 'id = ?',
          whereArgs: [existing.first['id'] as int],
        );
      }
    }
  }

  Future<void> _seedDefaults(Database db) async {
    const settings = {
      'reminder_enabled': '0',
      'reminder_hour': '21',
      'reminder_minute': '0',
      'pin_enabled': '0',
      'pin_hash': null,
      'pin_salt': null,
    };

    for (final entry in settings.entries) {
      await db.insert('settings', {'key': entry.key, 'value': entry.value});
    }
  }
}
