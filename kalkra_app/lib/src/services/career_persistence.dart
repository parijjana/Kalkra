import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_engine/game_engine.dart';

/// Service responsible for local persistence of player career data.
class CareerPersistence {
  static const String _careerKey = 'kalkra_career_data';
  final SharedPreferences _prefs;

  CareerPersistence(this._prefs);

  /// Loads the saved [CareerManager] data.
  /// Returns a default [CareerManager] if no data is found or if parsing fails.
  CareerManager load() {
    final String? jsonString = _prefs.getString(_careerKey);
    if (jsonString == null || jsonString.isEmpty) {
      return CareerManager();
    }

    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      return CareerManager.fromJson(json);
    } catch (e) {
      // In case of corruption or structural changes, fallback to default
      return CareerManager();
    }
  }

  /// Saves the [CareerManager] data to local storage.
  Future<bool> save(CareerManager career) async {
    final String jsonString = jsonEncode(career.toJson());
    return await _prefs.setString(_careerKey, jsonString);
  }

  /// Clears all local career data.
  Future<bool> clear() async {
    return await _prefs.remove(_careerKey);
  }
}
