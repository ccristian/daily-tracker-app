import 'package:flutter_test/flutter_test.dart';
import 'package:offline_daily_tracker/src/data/settings_repository.dart';
import 'package:offline_daily_tracker/src/models/settings.dart';
import 'package:offline_daily_tracker/src/services/app_lock_service.dart';
import 'package:offline_daily_tracker/src/services/secure_store.dart';

class InMemorySecureStore implements SecureStore {
  final _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

class InMemoryPinStore implements PinSettingsStore {
  AppSettings _settings = AppSettings.defaults;

  @override
  Future<AppSettings> getSettings() async {
    return _settings;
  }

  @override
  Future<void> setPinState({required bool enabled, String? hash, String? salt}) async {
    _settings = _settings.copyWith(pinEnabled: enabled, pinHash: hash, pinSalt: salt);
  }
}

void main() {
  group('AppLockService', () {
    late AppLockService service;

    setUp(() {
      service = AppLockService(InMemoryPinStore(), InMemorySecureStore());
    });

    test('enable and verify pin', () async {
      await service.enablePin('1234');
      expect(await service.isPinEnabled(), isTrue);
      expect(await service.verifyPin('1234'), isTrue);
      expect(await service.verifyPin('9999'), isFalse);
    });

    test('disable requires current pin', () async {
      await service.enablePin('1234');
      expect(await service.disablePin('9999'), isFalse);
      expect(await service.isPinEnabled(), isTrue);

      expect(await service.disablePin('1234'), isTrue);
      expect(await service.isPinEnabled(), isFalse);
    });
  });
}
