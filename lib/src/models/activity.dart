enum ActivityType { yesNo }

enum ActivityPolarity { doMore, doLess }

class ActivityCategory {
  static const health = 'health';
  static const fitness = 'fitness';
  static const mind = 'mind';
  static const productivity = 'productivity';
  static const reduce = 'reduce';

  static const orderedKeys = [
    health,
    fitness,
    mind,
    productivity,
    reduce,
  ];

  static String label(String key) {
    switch (key) {
      case health:
        return 'Health';
      case fitness:
        return 'Fitness';
      case mind:
        return 'Mind';
      case productivity:
        return 'Productivity';
      case reduce:
        return 'Reduce';
      default:
        return 'Other';
    }
  }
}

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
    this.systemKey,
    this.categoryKey = ActivityCategory.health,
    this.iconKey = 'check_circle',
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
  final String? systemKey;
  final String categoryKey;
  final String iconKey;

  int get allowedFailures => windowDays - targetSuccesses;
  String get categoryLabel => ActivityCategory.label(categoryKey);

  String get targetSummaryLabel {
    if (polarity == ActivityPolarity.doMore) {
      return 'Goal: at least $targetSuccesses/$windowDays days';
    }
    return 'Goal: avoid it on $targetSuccesses/$windowDays days (limit $allowedFailures/$windowDays)';
  }

  String get trackingHint {
    if (polarity == ActivityPolarity.doMore) {
      return 'Yes means you did this today.';
    }
    return 'Yes means it happened today. Keep Yes days under the limit.';
  }

  static String buildTargetLabel({
    required ActivityPolarity polarity,
    required int targetSuccesses,
    required int windowDays,
  }) {
    if (polarity == ActivityPolarity.doMore) {
      return 'Goal: at least $targetSuccesses/$windowDays days';
    }
    final allowedFailures = windowDays - targetSuccesses;
    return 'Goal: avoid it on $targetSuccesses/$windowDays days (limit $allowedFailures/$windowDays)';
  }

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
    String? systemKey,
    String? categoryKey,
    String? iconKey,
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
      systemKey: systemKey ?? this.systemKey,
      categoryKey: categoryKey ?? this.categoryKey,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  static ActivityType parseType(String value) => ActivityType.yesNo;

  static String typeToString(ActivityType type) => 'yes_no';

  static ActivityPolarity parsePolarity(String value) {
    return value == 'do_less'
        ? ActivityPolarity.doLess
        : ActivityPolarity.doMore;
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
