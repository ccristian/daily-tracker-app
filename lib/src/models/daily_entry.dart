class DailyEntry {
  const DailyEntry({
    required this.id,
    required this.activityId,
    required this.dateKey,
    required this.binaryValue,
    required this.scaleValue,
    required this.updatedAt,
  });

  final int id;
  final int activityId;
  final String dateKey;
  final bool? binaryValue;
  final int? scaleValue;
  final DateTime updatedAt;

  DailyEntry copyWith({
    int? id,
    int? activityId,
    String? dateKey,
    bool? binaryValue,
    int? scaleValue,
    DateTime? updatedAt,
  }) {
    return DailyEntry(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      dateKey: dateKey ?? this.dateKey,
      binaryValue: binaryValue ?? this.binaryValue,
      scaleValue: scaleValue ?? this.scaleValue,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
