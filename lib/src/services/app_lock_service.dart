import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../data/settings_repository.dart';
import '../models/settings.dart';
import 'secure_store.dart';

class AppLockService {
  AppLockService(this._settingsStore, this._secureStore);

  static const _pinHashKey = 'pin_hash';
  static const _pinSaltKey = 'pin_salt';

  final PinSettingsStore _settingsStore;
  final SecureStore _secureStore;

  Future<bool> isPinEnabled() async {
    final settings = await _settingsStore.getSettings();
    return settings.pinEnabled;
  }

  Future<bool> shouldLockOnResume() async => isPinEnabled();

  Future<void> enablePin(String pin) async {
    _validatePin(pin);
    final salt = _randomSalt();
    final hash = _hashPin(pin, salt);

    await _secureStore.write(_pinSaltKey, salt);
    await _secureStore.write(_pinHashKey, hash);
    await _settingsStore.setPinState(enabled: true, hash: hash, salt: salt);
  }

  Future<bool> verifyPin(String pin) async {
    _validatePin(pin);
    final settings = await _settingsStore.getSettings();
    if (!settings.pinEnabled) {
      return true;
    }

    final salt = await _secureStore.read(_pinSaltKey) ?? settings.pinSalt;
    final hash = await _secureStore.read(_pinHashKey) ?? settings.pinHash;
    if (salt == null || hash == null) {
      return false;
    }

    final candidate = _hashPin(pin, salt);
    return candidate == hash;
  }

  Future<bool> disablePin(String currentPin) async {
    final isValid = await verifyPin(currentPin);
    if (!isValid) {
      return false;
    }

    await _secureStore.delete(_pinSaltKey);
    await _secureStore.delete(_pinHashKey);
    await _settingsStore.setPinState(enabled: false, hash: null, salt: null);
    return true;
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    final isValid = await verifyPin(currentPin);
    if (!isValid) {
      return false;
    }
    await enablePin(newPin);
    return true;
  }

  Future<AppSettings> getSettings() => _settingsStore.getSettings();

  void _validatePin(String pin) {
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      throw ArgumentError('PIN must be exactly 4 digits');
    }
  }

  String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
