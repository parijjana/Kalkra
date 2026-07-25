import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
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
          // Best-effort upgrade to encrypted storage. save() never throws --
          // if it fails (e.g. a transient keychain error) we keep the legacy
          // key around so the next load() retries the migration, but we
          // still return the manager we already parsed rather than losing it.
          final migrated = await save(manager, deviceId);
          if (migrated) {
            await _prefs.remove(_legacyKey);
          }
          return manager;
        } catch (_) {
          // Legacy JSON itself is malformed -- nothing to salvage.
        }
      }
      return CareerManager();
    }

    try {
      final String jsonString = await PersistenceSecurity.unpack(
        packedData,
        deviceId,
      );
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return CareerManager.fromJson(json);
    } on UnrecoverableVaultException {
      // The vault is genuinely undecryptable (lost/rotated master key) --
      // there's nothing to recover, so start fresh.
      return CareerManager();
    } on PlatformException catch (e) {
      // A transient/unknown failure from the storage plugin itself (e.g. the
      // keychain being temporarily unavailable), as opposed to the data
      // being corrupt. Resetting here would silently overwrite the real
      // save the next time anything calls save(). Instead, let this
      // propagate so the caller (CareerNotifier.build) surfaces it as an
      // error state rather than a fresh, saveable-over career.
      debugPrint('CareerPersistence.load: transient storage failure: $e');
      rethrow;
    } catch (e) {
      // Structurally corrupt data (bad JSON/format) -> reset is safe here,
      // it's not a storage failure that could recur and clobber real data.
      debugPrint('CareerPersistence.load: corrupt career data, resetting: $e');
      return CareerManager();
    }
  }

  /// Saves the [CareerManager] data to local storage.
  ///
  /// Never throws: storage failures (e.g. a keychain entitlement error) are
  /// caught and reported via the return value so a failed save can never
  /// crash the app. In-memory state remains authoritative regardless.
  Future<bool> save(CareerManager career, String deviceId) async {
    try {
      final String jsonString = jsonEncode(career.toJson());
      final String packed = await PersistenceSecurity.pack(
        jsonString,
        deviceId,
      );
      return await _prefs.setString(_careerKey, packed);
    } catch (e) {
      debugPrint('CareerPersistence.save: failed to persist career data: $e');
      return false;
    }
  }

  /// Clears all local career data.
  Future<bool> clear() async {
    await _prefs.remove(_legacyKey);
    return await _prefs.remove(_careerKey);
  }
}
