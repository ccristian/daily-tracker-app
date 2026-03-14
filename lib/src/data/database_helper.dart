import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'predefined_activities.dart';

class DatabaseHelper {
  DatabaseHelper();

  static const _dbName = 'daily_tracker.db';
  static const _dbVersion = 6;

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
        system_key TEXT,
        category_key TEXT NOT NULL DEFAULT 'health',
        icon_key TEXT NOT NULL DEFAULT 'check_circle',
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
    await db.execute(
        'CREATE INDEX idx_daily_entries_date ON daily_entries(date_key)');

    await _applyDefaultActivities(db);
    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          "ALTER TABLE activities ADD COLUMN polarity TEXT NOT NULL DEFAULT 'do_more'");
      await db.execute(
          'ALTER TABLE activities ADD COLUMN window_days INTEGER NOT NULL DEFAULT 7');
      await db.execute(
          'ALTER TABLE activities ADD COLUMN target_successes INTEGER NOT NULL DEFAULT 7');
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

    if (oldVersion < 5) {
      await db.execute(
        "ALTER TABLE activities ADD COLUMN category_key TEXT NOT NULL DEFAULT 'health'",
      );
      await db.execute(
        "ALTER TABLE activities ADD COLUMN icon_key TEXT NOT NULL DEFAULT 'check_circle'",
      );
      await _applyDefaultActivities(db);
    }

    if (oldVersion < 6) {
      await db.execute('ALTER TABLE activities ADD COLUMN system_key TEXT');
      await _backfillSystemKeys(db);
      await _applyDefaultActivities(db);
    }
  }

  Future<void> _applyDefaultActivities(Database db) async {
    final now = DateTime.now().toIso8601String();
    final currentSystemKeys =
        predefinedActivitySpecs.map((spec) => spec.systemKey).toSet();

    final existingDefaults = await db.query(
      'activities',
      columns: ['id', 'name', 'system_key', 'is_active'],
      where: 'is_predefined = 1 AND deleted_at IS NULL',
    );

    for (final row in existingDefaults) {
      final systemKey = row['system_key'] as String?;
      if (systemKey != null && !currentSystemKeys.contains(systemKey)) {
        await db.update(
          'activities',
          {
            'is_active': 0,
            'deleted_at': now,
          },
          where: 'id = ?',
          whereArgs: [row['id'] as int],
        );
      }
    }

    for (final spec in predefinedActivitySpecs) {
      final existing = await _findExistingPredefinedRow(db, spec);

      if (existing.isEmpty) {
        await db.insert('activities', {
          'name': spec.name,
          'type': 'yes_no',
          'polarity': spec.polarity,
          'system_key': spec.systemKey,
          'category_key': spec.categoryKey,
          'icon_key': spec.iconKey,
          'window_days': 7,
          'target_successes': spec.targetSuccesses,
          'is_predefined': 1,
          'is_active': spec.isActiveByDefault ? 1 : 0,
          'created_at': now,
          'deleted_at': null,
        });
      } else {
        final currentIsActive = existing.first['is_active'] as int? ??
            (spec.isActiveByDefault ? 1 : 0);
        await db.update(
          'activities',
          {
            'name': spec.name,
            'type': 'yes_no',
            'polarity': spec.polarity,
            'system_key': spec.systemKey,
            'category_key': spec.categoryKey,
            'icon_key': spec.iconKey,
            'window_days': 7,
            'target_successes': spec.targetSuccesses,
            'is_predefined': 1,
            'is_active': currentIsActive,
            'deleted_at': null,
          },
          where: 'id = ?',
          whereArgs: [existing.first['id'] as int],
        );
      }
    }
  }

  Future<void> _backfillSystemKeys(Database db) async {
    final rows = await db.query(
      'activities',
      columns: ['id', 'name', 'is_predefined', 'system_key'],
      where: 'deleted_at IS NULL',
    );

    for (final row in rows) {
      if ((row['is_predefined'] as int? ?? 0) != 1) {
        continue;
      }
      if ((row['system_key'] as String?) != null) {
        continue;
      }
      final name = row['name'] as String? ?? '';
      final systemKey = resolvePredefinedSystemKeyFromName(name);
      if (systemKey == null) {
        continue;
      }
      await db.update(
        'activities',
        {'system_key': systemKey},
        where: 'id = ?',
        whereArgs: [row['id'] as int],
      );
    }
  }

  Future<List<Map<String, Object?>>> _findExistingPredefinedRow(
    Database db,
    PredefinedActivitySpec spec,
  ) async {
    final bySystemKey = await db.query(
      'activities',
      columns: ['id', 'is_active'],
      where: 'system_key = ? AND deleted_at IS NULL',
      whereArgs: [spec.systemKey],
      limit: 1,
    );
    if (bySystemKey.isNotEmpty) {
      return bySystemKey;
    }

    final aliases = predefinedActivityAliases.entries
        .where((entry) => entry.value == spec.systemKey)
        .map((entry) => entry.key)
        .toList();
    if (aliases.isEmpty) {
      return const [];
    }

    final placeholders = List.filled(aliases.length, '?').join(', ');
    return db.query(
      'activities',
      columns: ['id', 'is_active'],
      where: 'LOWER(name) IN ($placeholders) AND deleted_at IS NULL',
      whereArgs: aliases,
      limit: 1,
    );
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
