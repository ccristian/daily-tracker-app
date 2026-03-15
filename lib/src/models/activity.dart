enum ActivityType { yesNo }

enum ActivityPolarity { doMore, doLess }

class ActivityCategoryDefinition {
  const ActivityCategoryDefinition({
    required this.key,
    required this.label,
    this.iconKey,
  });

  final String key;
  final String label;
  final String? iconKey;

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        if (iconKey != null) 'iconKey': iconKey,
      };

  ActivityCategoryDefinition copyWith({
    String? key,
    String? label,
    String? iconKey,
  }) {
    return ActivityCategoryDefinition(
      key: key ?? this.key,
      label: label ?? this.label,
      iconKey: iconKey ?? this.iconKey,
    );
  }

  static ActivityCategoryDefinition? fromJson(Map<String, dynamic> json) {
    final key = (json['key'] as String?)?.trim();
    final label = (json['label'] as String?)?.trim();
    final iconKey = (json['iconKey'] as String?)?.trim();
    if (key == null || key.isEmpty || label == null || label.isEmpty) {
      return null;
    }
    return ActivityCategoryDefinition(
      key: key,
      label: label,
      iconKey: iconKey == null || iconKey.isEmpty ? null : iconKey,
    );
  }
}

class ActivityCategory {
  static const health = 'health';
  static const fitness = 'fitness';
  static const mind = 'mind';
  static const productivity = 'productivity';
  static const reduce = 'reduce';

  static const customIconPool = [
    'pets',
    'music_note',
    'palette',
    'travel',
    'laptop',
    'spa',
    'park',
    'home',
    'savings',
    'sparkles',
    'restaurant',
    'camera',
    'sports',
    'code',
    'book',
    'movie',
    'shopping',
    'car',
    'flight',
    'gamepad',
  ];

  static const defaultDefinitions = [
    ActivityCategoryDefinition(
      key: health,
      label: 'Health',
      iconKey: 'favorite_outline',
    ),
    ActivityCategoryDefinition(
      key: fitness,
      label: 'Fitness',
      iconKey: 'fitness_center',
    ),
    ActivityCategoryDefinition(
      key: mind,
      label: 'Mind',
      iconKey: 'self_improvement',
    ),
    ActivityCategoryDefinition(
      key: productivity,
      label: 'Productivity',
      iconKey: 'bolt_outlined',
    ),
    ActivityCategoryDefinition(
      key: reduce,
      label: 'Reduce',
      iconKey: 'remove_circle_outline',
    ),
  ];

  static const orderedKeys = [
    health,
    fitness,
    mind,
    productivity,
    reduce,
  ];

  static const fallbackKey = health;

  static bool isDefaultKey(String key) => orderedKeys.contains(key);

  static ActivityCategoryDefinition? definitionFor(
    String key,
    List<ActivityCategoryDefinition> categories,
  ) {
    for (final category in categories) {
      if (category.key == key) {
        return category;
      }
    }
    return null;
  }

  static String label(String key) {
    for (final definition in defaultDefinitions) {
      if (definition.key == key) {
        return definition.label;
      }
    }
    return labelFromKey(key);
  }

  static String labelFor(
    String key,
    List<ActivityCategoryDefinition> categories,
  ) {
    for (final category in categories) {
      if (category.key == key) {
        return category.label;
      }
    }
    return label(key);
  }

  static String labelFromKey(String key) {
    final cleaned = key.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (cleaned.isEmpty) {
      return 'Other';
    }
    return cleaned
        .split(RegExp(r'\s+'))
        .map((part) =>
            '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String buildKey(
    String label, {
    Iterable<String> existingKeys = const [],
  }) {
    final slug = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final baseKey = slug.isEmpty ? 'category' : slug;
    final existing = existingKeys.toSet();
    var candidate = baseKey;
    var suffix = 2;
    while (existing.contains(candidate)) {
      candidate = '${baseKey}_$suffix';
      suffix += 1;
    }
    return candidate;
  }

  static List<ActivityCategoryDefinition> sanitizeDefinitions(
    List<ActivityCategoryDefinition> categories,
  ) {
    final sanitized = <ActivityCategoryDefinition>[];
    final seenKeys = <String>{};
    for (final category in categories) {
      final key = category.key.trim();
      final label = category.label.trim();
      if (key.isEmpty || label.isEmpty || seenKeys.contains(key)) {
        continue;
      }
      sanitized.add(
        ActivityCategoryDefinition(
          key: key,
          label: label,
          iconKey: category.iconKey?.trim(),
        ),
      );
      seenKeys.add(key);
    }
    return sanitized.isEmpty
        ? defaultDefinitions
        : _assignCategoryIcons(sanitized);
  }

  static String labelOrDefault(
    String key, {
    List<ActivityCategoryDefinition>? categories,
  }) {
    if (categories != null) {
      return labelFor(key, categories);
    }
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

  static String nextCustomIconKey(
    Iterable<ActivityCategoryDefinition> categories,
  ) {
    final used = categories
        .where((category) => !isDefaultKey(category.key))
        .map((category) => category.iconKey)
        .whereType<String>()
        .where(customIconPool.contains)
        .toSet();

    for (final iconKey in customIconPool) {
      if (!used.contains(iconKey)) {
        return iconKey;
      }
    }

    return customIconPool[used.length % customIconPool.length];
  }

  static List<ActivityCategoryDefinition> _assignCategoryIcons(
    List<ActivityCategoryDefinition> categories,
  ) {
    final normalized = <ActivityCategoryDefinition>[];
    final usedCustomIcons = <String>{};

    for (final category in categories) {
      if (isDefaultKey(category.key)) {
        final fallback = defaultDefinitions.firstWhere(
          (definition) => definition.key == category.key,
        );
        normalized.add(
          category.copyWith(iconKey: category.iconKey ?? fallback.iconKey),
        );
        continue;
      }

      final currentIconKey = category.iconKey;
      if (currentIconKey != null &&
          customIconPool.contains(currentIconKey) &&
          !usedCustomIcons.contains(currentIconKey)) {
        usedCustomIcons.add(currentIconKey);
        normalized.add(category);
        continue;
      }

      final nextIconKey = customIconPool.firstWhere(
        (iconKey) => !usedCustomIcons.contains(iconKey),
        orElse: () => customIconPool[usedCustomIcons.length % customIconPool.length],
      );
      usedCustomIcons.add(nextIconKey);
      normalized.add(category.copyWith(iconKey: nextIconKey));
    }

    return normalized;
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
  String get categoryLabel => ActivityCategory.labelOrDefault(categoryKey);

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
