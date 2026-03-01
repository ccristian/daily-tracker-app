enum ActivityType { yesNo }

enum ActivityPolarity { doMore, doLess }

class Activity {
  const Activity({
    required this.id,
    required this.name,
    required this.type,
    required this.polarity,
    required this.windowDays,
    required this.targetSuccesses,
    required this.isPredefined,
    required this.isActive,
    required this.createdAt,
    required this.deletedAt,
  });

  final int id;
  final String name;
  final ActivityType type;
  final ActivityPolarity polarity;
  final int windowDays;
  final int targetSuccesses;
  final bool isPredefined;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? deletedAt;

  int get allowedFailures => windowDays - targetSuccesses;

  Activity copyWith({
    int? id,
    String? name,
    ActivityType? type,
    ActivityPolarity? polarity,
    int? windowDays,
    int? targetSuccesses,
    bool? isPredefined,
    bool? isActive,
    DateTime? createdAt,
    DateTime? deletedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      polarity: polarity ?? this.polarity,
      windowDays: windowDays ?? this.windowDays,
      targetSuccesses: targetSuccesses ?? this.targetSuccesses,
      isPredefined: isPredefined ?? this.isPredefined,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  static ActivityType parseType(String value) => ActivityType.yesNo;

  static String typeToString(ActivityType type) => 'yes_no';

  static ActivityPolarity parsePolarity(String value) {
    return value == 'do_less' ? ActivityPolarity.doLess : ActivityPolarity.doMore;
  }

  static String polarityToString(ActivityPolarity polarity) {
    return polarity == ActivityPolarity.doLess ? 'do_less' : 'do_more';
  }
}

class ActivityWindowSummary {
  const ActivityWindowSummary({
    required this.doneDays,
    required this.met,
  });

  final int doneDays;
  final bool met;
}
