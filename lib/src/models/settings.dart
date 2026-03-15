import 'activity.dart';

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  ReminderSettings copyWith({
    bool? enabled,
    int? hour,
    int? minute,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.reminderSettings,
    required this.pinEnabled,
    required this.pinHash,
    required this.pinSalt,
    required this.categories,
  });

  final ReminderSettings reminderSettings;
  final bool pinEnabled;
  final String? pinHash;
  final String? pinSalt;
  final List<ActivityCategoryDefinition> categories;

  AppSettings copyWith({
    ReminderSettings? reminderSettings,
    bool? pinEnabled,
    String? pinHash,
    String? pinSalt,
    List<ActivityCategoryDefinition>? categories,
  }) {
    return AppSettings(
      reminderSettings: reminderSettings ?? this.reminderSettings,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinHash: pinHash ?? this.pinHash,
      pinSalt: pinSalt ?? this.pinSalt,
      categories: categories ?? this.categories,
    );
  }

  static const defaults = AppSettings(
    reminderSettings: ReminderSettings(enabled: false, hour: 21, minute: 0),
    pinEnabled: false,
    pinHash: null,
    pinSalt: null,
    categories: ActivityCategory.defaultDefinitions,
  );
}
