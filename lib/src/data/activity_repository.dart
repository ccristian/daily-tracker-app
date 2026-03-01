import '../models/activity.dart';
import 'database_helper.dart';

class ActivityRepository {
  ActivityRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<List<Activity>> getAllActivities({bool includeInactive = true}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'activities',
      orderBy: 'is_predefined DESC, id ASC',
      where: includeInactive
          ? 'deleted_at IS NULL'
          : 'is_active = 1 AND deleted_at IS NULL',
    );
    return rows.map(_toActivity).toList();
  }

  Future<Activity> addCustomActivity({
    required String name,
    required ActivityPolarity polarity,
    required int windowDays,
    required int targetSuccesses,
  }) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final id = await db.insert('activities', {
      'name': name.trim(),
      'type': Activity.typeToString(ActivityType.yesNo),
      'polarity': Activity.polarityToString(polarity),
      'window_days': windowDays,
      'target_successes': targetSuccesses,
      'is_predefined': 0,
      'is_active': 1,
      'created_at': now.toIso8601String(),
      'deleted_at': null,
    });
    return Activity(
      id: id,
      name: name.trim(),
      type: ActivityType.yesNo,
      polarity: polarity,
      windowDays: windowDays,
      targetSuccesses: targetSuccesses,
      isPredefined: false,
      isActive: true,
      createdAt: now,
      deletedAt: null,
    );
  }

  Future<void> updateActivityConfig({
    required int activityId,
    required String name,
    required ActivityPolarity polarity,
    required int windowDays,
    required int targetSuccesses,
    required bool isActive,
  }) async {
    final db = await _dbHelper.database;
    await db.update(
      'activities',
      {
        'name': name.trim(),
        'polarity': Activity.polarityToString(polarity),
        'window_days': windowDays,
        'target_successes': targetSuccesses,
        'is_active': isActive ? 1 : 0,
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [activityId],
    );
  }

  Future<void> setActive(int activityId, bool isActive) async {
    final db = await _dbHelper.database;
    await db.update(
      'activities',
      {'is_active': isActive ? 1 : 0},
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [activityId],
    );
  }

  Future<void> softDelete(int activityId) async {
    final db = await _dbHelper.database;
    await db.update(
      'activities',
      {
        'is_active': 0,
        'deleted_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND deleted_at IS NULL',
      whereArgs: [activityId],
    );
  }

  Future<bool> existsByName(String name, {int? excludeId}) async {
    final db = await _dbHelper.database;
    final where = StringBuffer('LOWER(name) = LOWER(?) AND deleted_at IS NULL');
    final whereArgs = <Object?>[name.trim()];

    if (excludeId != null) {
      where.write(' AND id != ?');
      whereArgs.add(excludeId);
    }

    final rows = await db.query(
      'activities',
      columns: ['id'],
      where: where.toString(),
      whereArgs: whereArgs,
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Activity _toActivity(Map<String, Object?> row) {
    return Activity(
      id: row['id'] as int,
      name: row['name'] as String,
      type: Activity.parseType(row['type'] as String),
      polarity: Activity.parsePolarity((row['polarity'] as String?) ?? 'do_more'),
      windowDays: (row['window_days'] as int?) ?? 7,
      targetSuccesses: (row['target_successes'] as int?) ?? 7,
      isPredefined: (row['is_predefined'] as int) == 1,
      isActive: (row['is_active'] as int) == 1,
      createdAt: DateTime.parse(row['created_at'] as String),
      deletedAt: row['deleted_at'] == null ? null : DateTime.parse(row['deleted_at'] as String),
    );
  }
}
