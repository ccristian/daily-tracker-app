import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/activity.dart';
import '../models/settings.dart';
import 'database_helper.dart';

abstract class PinSettingsStore {
  Future<AppSettings> getSettings();
  Future<void> setPinState({
    required bool enabled,
    String? hash,
    String? salt,
  });
}

class SettingsRepository implements PinSettingsStore {
  SettingsRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;
  static const _activityCategoriesKey = 'activity_categories';

  @override
  Future<AppSettings> getSettings() async {
    final db = await _dbHelper.database;
    final rows = await db.query('settings');
    final map = <String, String?>{};
    for (final row in rows) {
      map[row['key'] as String] = row['value'] as String?;
    }

    return AppSettings(
      reminderSettings: ReminderSettings(
        enabled: (map['reminder_enabled'] ?? '0') == '1',
        hour: int.tryParse(map['reminder_hour'] ?? '21') ?? 21,
        minute: int.tryParse(map['reminder_minute'] ?? '0') ?? 0,
      ),
      pinEnabled: (map['pin_enabled'] ?? '0') == '1',
      pinHash: map['pin_hash'],
      pinSalt: map['pin_salt'],
      categories: _parseCategories(map[_activityCategoriesKey]),
    );
  }

  Future<void> updateReminder(ReminderSettings reminder) async {
    final db = await _dbHelper.database;
    await _upsert(db, 'reminder_enabled', reminder.enabled ? '1' : '0');
    await _upsert(db, 'reminder_hour', reminder.hour.toString());
    await _upsert(db, 'reminder_minute', reminder.minute.toString());
  }

  @override
  Future<void> setPinState({
    required bool enabled,
    String? hash,
    String? salt,
  }) async {
    final db = await _dbHelper.database;
    await _upsert(db, 'pin_enabled', enabled ? '1' : '0');
    await _upsert(db, 'pin_hash', hash);
    await _upsert(db, 'pin_salt', salt);
  }

  Future<void> updateCategories(
    List<ActivityCategoryDefinition> categories,
  ) async {
    final db = await _dbHelper.database;
    final sanitized = ActivityCategory.sanitizeDefinitions(categories);
    await _upsert(
      db,
      _activityCategoriesKey,
      jsonEncode(
        sanitized.map((category) => category.toJson()).toList(),
      ),
    );
  }

  List<ActivityCategoryDefinition> _parseCategories(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return ActivityCategory.defaultDefinitions;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return ActivityCategory.defaultDefinitions;
      }

      final categories = decoded
          .whereType<Map>()
          .map(
            (entry) =>
                ActivityCategoryDefinition.fromJson(entry.cast<String, dynamic>()),
          )
          .whereType<ActivityCategoryDefinition>()
          .toList();
      return ActivityCategory.sanitizeDefinitions(categories);
    } catch (_) {
      return ActivityCategory.defaultDefinitions;
    }
  }

  Future<void> _upsert(Database db, String key, String? value) async {
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
