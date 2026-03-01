import 'package:sqflite/sqflite.dart';

import '../models/activity.dart';
import '../models/daily_entry.dart';
import 'database_helper.dart';
import 'date_key.dart';

class DayActivityRecordRaw {
  const DayActivityRecordRaw({
    required this.activityId,
    required this.activityName,
    required this.dateKey,
    required this.done,
    required this.isActive,
    required this.isDeleted,
  });

  final int activityId;
  final String activityName;
  final String dateKey;
  final bool done;
  final bool isActive;
  final bool isDeleted;
}

class DailyEntryRepository {
  DailyEntryRepository(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<Map<int, DailyEntry>> getEntriesByDate(DateTime date) async {
    final db = await _dbHelper.database;
    final dateKey = dateToKey(date);
    final rows = await db.query(
      'daily_entries',
      where: 'date_key = ?',
      whereArgs: [dateKey],
    );

    final output = <int, DailyEntry>{};
    for (final row in rows) {
      final entry = _toEntry(row);
      output[entry.activityId] = entry;
    }
    return output;
  }

  Future<void> upsertEntry({
    required Activity activity,
    required DateTime date,
    bool? binaryValue,
  }) async {
    final db = await _dbHelper.database;
    final dateKey = dateToKey(date);

    if (activity.type == ActivityType.yesNo) {
      if (binaryValue == null) {
        throw ArgumentError('yesNo value is required for activity');
      }
    }

    await db.insert(
      'daily_entries',
      {
        'activity_id': activity.id,
        'date_key': dateKey,
        'binary_value': binaryValue == null ? null : (binaryValue ? 1 : 0),
        'scale_value': null,
        'updated_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<String>> getCompletionDateKeysForActivity(int activityId) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      '''
      SELECT date_key
      FROM daily_entries
      WHERE activity_id = ?
        AND (binary_value = 1 OR scale_value IS NOT NULL)
      ORDER BY date_key DESC
      ''',
      [activityId],
    );
    return rows.map((row) => row['date_key'] as String).toList();
  }

  Future<List<String>> getCompletionDateKeysForActivityInRange({
    required int activityId,
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _dbHelper.database;
    final startKey = dateToKey(start);
    final endKey = dateToKey(end);
    final rows = await db.rawQuery(
      '''
      SELECT date_key
      FROM daily_entries
      WHERE activity_id = ?
        AND date_key >= ?
        AND date_key <= ?
        AND (binary_value = 1 OR scale_value IS NOT NULL)
      ORDER BY date_key ASC
      ''',
      [activityId, startKey, endKey],
    );
    return rows.map((row) => row['date_key'] as String).toList();
  }

  Future<Map<String, Map<int, DailyEntry>>> getEntriesForLastDays(
      int days) async {
    final db = await _dbHelper.database;
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    final startKey = dateToKey(start);
    final endKey = dateToKey(end);

    final rows = await db.query(
      'daily_entries',
      where: 'date_key >= ? AND date_key <= ?',
      whereArgs: [startKey, endKey],
      orderBy: 'date_key ASC',
    );

    final byDate = <String, Map<int, DailyEntry>>{};
    for (final row in rows) {
      final entry = _toEntry(row);
      byDate.putIfAbsent(entry.dateKey, () => {});
      byDate[entry.dateKey]![entry.activityId] = entry;
    }
    return byDate;
  }

  Future<Map<String, List<DayActivityRecordRaw>>> getMonthActivityRecords({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _dbHelper.database;
    final startKey = dateToKey(start);
    final endKey = dateToKey(end);

    final rows = await db.rawQuery(
      '''
      SELECT
        de.date_key AS date_key,
        de.activity_id AS activity_id,
        a.name AS activity_name,
        de.binary_value AS binary_value,
        de.scale_value AS scale_value,
        COALESCE(a.is_active, 0) AS is_active,
        a.deleted_at AS deleted_at
      FROM daily_entries de
      LEFT JOIN activities a ON a.id = de.activity_id
      WHERE de.date_key >= ?
        AND de.date_key <= ?
        AND (de.binary_value = 1 OR de.scale_value IS NOT NULL)
      ORDER BY de.date_key ASC, de.activity_id ASC
      ''',
      [startKey, endKey],
    );

    final output = <String, List<DayActivityRecordRaw>>{};
    for (final row in rows) {
      final dateKey = row['date_key'] as String;
      output.putIfAbsent(dateKey, () => <DayActivityRecordRaw>[]);
      output[dateKey]!.add(
        DayActivityRecordRaw(
          activityId: row['activity_id'] as int,
          activityName:
              (row['activity_name'] as String?) ?? 'Archived Activity',
          dateKey: dateKey,
          done: ((row['binary_value'] as int?) == 1) ||
              (row['scale_value'] as int?) != null,
          isActive: (row['is_active'] as int?) == 1,
          isDeleted: row['deleted_at'] != null,
        ),
      );
    }
    return output;
  }

  Future<Map<String, Set<int>>> getMonthDoneActivityIds({
    required DateTime start,
    required DateTime end,
  }) async {
    final recordsByDate = await getMonthActivityRecords(start: start, end: end);
    final output = <String, Set<int>>{};
    recordsByDate.forEach((dateKey, records) {
      output[dateKey] = records
          .where((record) => record.done)
          .map((record) => record.activityId)
          .toSet();
    });
    return output;
  }

  DailyEntry _toEntry(Map<String, Object?> row) {
    final binaryRaw = row['binary_value'] as int?;
    return DailyEntry(
      id: row['id'] as int,
      activityId: row['activity_id'] as int,
      dateKey: row['date_key'] as String,
      binaryValue: binaryRaw == null ? null : binaryRaw == 1,
      scaleValue: row['scale_value'] as int?,
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }
}
