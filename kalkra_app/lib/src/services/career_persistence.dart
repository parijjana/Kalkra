import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_engine/game_engine.dart';
import 'persistence_security.dart';

/// Service responsible for local persistence of player career data.
class CareerPersistence {
  static const String _careerKey =
      'kalkra_career_vault'; // New key for encrypted data
  static const String _legacyKey = 'kalkra_career_data';
  final SharedPreferences _prefs;

  CareerPersistence(this._prefs);

  /// Loads the saved [CareerManager] data.
  /// Returns a default [CareerManager] if no data is found or if parsing fails.
  Future<CareerManager> load(String deviceId) async {
    final String? packedData = _prefs.getString(_careerKey);

    // Migration: Check for legacy plain-text data first
    if (packedData == null) {
      final legacyJson = _prefs.getString(_legacyKey);
      if (legacyJson != null) {
        try {
          final manager = CareerManager.fromJson(jsonDecode(legacyJson));
          // Immediately upgrade to encrypted storage
          await save(manager, deviceId);
          await _prefs.remove(_legacyKey);
          return manager;
        } catch (_) {}
      }
      return CareerManager();
    }

    try {
      final String jsonString = PersistenceSecurity.unpack(
        packedData,
        deviceId,
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return CareerManager.fromJson(json);
    } catch (e) {
      // Data is tampered or corrupted -> Reset for safety
      return CareerManager();
    }
  }

  /// Saves the [CareerManager] data to local storage.
  Future<bool> save(CareerManager career, String deviceId) async {
    final String jsonString = jsonEncode(career.toJson());
    final String packed = PersistenceSecurity.pack(jsonString, deviceId);
    return await _prefs.setString(_careerKey, packed);
  }

  /// Clears all local career data.
  Future<bool> clear() async {
    await _prefs.remove(_legacyKey);
    return await _prefs.remove(_careerKey);
  }
}
