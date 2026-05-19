import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_engine/game_engine.dart';
import 'package:kalkra/src/services/career_persistence.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CareerPersistence', () {
    late SharedPreferences prefs;
    late CareerPersistence persistence;
    const deviceId = 'test-device-id';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      persistence = CareerPersistence(prefs);
    });

    test('load() returns default CareerManager when no data exists', () async {
      final manager = await persistence.load(deviceId);
      expect(manager.playerName, 'Guest'); // Default in CareerManager
      expect(manager.elo, 1200);
    });

    test('save() and load() persists CareerManager data including audio prefs', () async {
      final manager = CareerManager(
        playerName: 'TestPlayer',
        elo: 1500,
        soundEnabled: false,
        musicEnabled: false,
        sfxVolume: 0.5,
        bgmVolume: 0.2,
        enabledTracks: {'test_track.ogg'},
      );
      await persistence.save(manager, deviceId);

      final loaded = await persistence.load(deviceId);
      expect(loaded.playerName, 'TestPlayer');
      expect(loaded.elo, 1500);
      expect(loaded.soundEnabled, isFalse);
      expect(loaded.musicEnabled, isFalse);
      expect(loaded.sfxVolume, 0.5);
      expect(loaded.bgmVolume, 0.2);
      expect(loaded.enabledTracks, contains('test_track.ogg'));
    });

    test('migration from legacy data works', () async {
      final manager = CareerManager(playerName: 'LegacyUser', elo: 1300);
      await prefs.setString('kalkra_career_data', jsonEncode(manager.toJson()));

      final loaded = await persistence.load(deviceId);
      expect(loaded.playerName, 'LegacyUser');
      
      // Verify it was migrated to encrypted storage
      expect(prefs.containsKey('kalkra_career_vault'), isTrue);
      expect(prefs.containsKey('kalkra_career_data'), isFalse);
    });

    test('clears data correctly', () async {
      final manager = CareerManager(playerName: 'ToClear');
      await persistence.save(manager, deviceId);
      await persistence.clear();

      final loaded = await persistence.load(deviceId);
      expect(loaded.playerName, 'Guest'); // Back to default
    });

    test('handles tampered data by resetting', () async {
      await prefs.setString('kalkra_career_vault', 'invalid-data:tampered:hmac');
      
      final loaded = await persistence.load(deviceId);
      expect(loaded.playerName, 'Guest'); // Reset to default
    });
  });
}
