import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_engine/game_engine.dart';
import 'package:kalkra/src/services/career_persistence.dart';
import 'package:kalkra/src/services/persistence_security.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A [FlutterSecureStorage] stand-in that always throws, simulating the
/// kind of platform failure that previously crashed the app on macOS
/// (errSecMissingEntitlement / -34018), or any other transient keychain
/// unavailability.
class _ThrowingSecureStorage extends FlutterSecureStorage {
  const _ThrowingSecureStorage();

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    throw PlatformException(
      code: 'errSecMissingEntitlement',
      message: '-34018',
    );
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) {
    throw PlatformException(
      code: 'errSecMissingEntitlement',
      message: '-34018',
    );
  }
}

/// A [SharedPreferences] stand-in whose reads fail with a [PlatformException],
/// simulating the preferences backend itself being transiently unavailable
/// (as opposed to the stored data being corrupt).
///
/// Writes, removals, and key checks delegate to a real instance so the test
/// can verify that nothing was clobbered.
class _ThrowingReadPrefs implements SharedPreferences {
  _ThrowingReadPrefs(this._inner);

  final SharedPreferences _inner;

  @override
  String? getString(String key) {
    throw PlatformException(
      code: 'channel-error',
      message: 'preferences backend unavailable',
    );
  }

  @override
  Future<bool> setString(String key, String value) =>
      _inner.setString(key, value);

  @override
  Future<bool> remove(String key) => _inner.remove(key);

  @override
  bool containsKey(String key) => _inner.containsKey(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CareerPersistence', () {
    late SharedPreferences prefs;
    late CareerPersistence persistence;
    const deviceId = 'test-device-id';

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      PersistenceSecurity.storage = const FlutterSecureStorage();
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

    test(
      'save() swallows storage failures and reports failure instead of throwing',
      () async {
        final manager = CareerManager(playerName: 'WillFailToSave', elo: 1400);
        PersistenceSecurity.storage = const _ThrowingSecureStorage();

        // Must not throw -- a failed save is reported via the return value.
        final result = await persistence.save(manager, deviceId);

        expect(result, isFalse);
        // Nothing should have been written for a save that never completed.
        expect(prefs.containsKey('kalkra_career_vault'), isFalse);
      },
    );

    test(
      'a transient storage failure during legacy migration does not lose '
      'the existing save',
      () async {
        // Seed legacy (pre-encryption) save data, as if migrating an old
        // install.
        final manager = CareerManager(playerName: 'LegacyUser', elo: 1300);
        await prefs.setString(
          'kalkra_career_data',
          jsonEncode(manager.toJson()),
        );

        // Simulate the keychain being unavailable for the re-encrypt-and-save
        // step that load() attempts as part of migration.
        PersistenceSecurity.storage = const _ThrowingSecureStorage();

        final loaded = await persistence.load(deviceId);

        // The already-parsed legacy data must still be returned -- it must
        // not be discarded just because the follow-up encrypted save failed.
        expect(loaded.playerName, 'LegacyUser');
        expect(loaded.elo, 1300);

        // The legacy copy must be preserved (not clobbered/removed) since
        // the migration didn't actually succeed, so a later load can retry.
        expect(prefs.containsKey('kalkra_career_data'), isTrue);
        expect(prefs.containsKey('kalkra_career_vault'), isFalse);

        // Once storage recovers, a subsequent load should complete the
        // migration normally.
        PersistenceSecurity.storage = const FlutterSecureStorage();
        final loadedAgain = await persistence.load(deviceId);

        expect(loadedAgain.playerName, 'LegacyUser');
        expect(prefs.containsKey('kalkra_career_vault'), isTrue);
        expect(prefs.containsKey('kalkra_career_data'), isFalse);
      },
    );

    test(
      'load() rethrows a transient storage failure instead of resetting, '
      'leaving the stored save untouched',
      () async {
        // A real, healthy save exists on disk.
        final manager = CareerManager(playerName: 'RealPlayer', elo: 1500);
        await persistence.save(manager, deviceId);
        final storedVault = prefs.getString('kalkra_career_vault');
        expect(storedVault, isNotNull);

        // The storage layer now fails transiently with a PlatformException.
        // load() must NOT swallow this and return a fresh CareerManager --
        // that fresh manager would be saved over the real data on the next
        // mutation. It must propagate so the caller surfaces an error state.
        final failing = CareerPersistence(_ThrowingReadPrefs(prefs));

        await expectLater(
          failing.load(deviceId),
          throwsA(
            isA<PlatformException>()
                .having((e) => e.code, 'code', 'channel-error'),
          ),
        );

        // The stored save must not have been overwritten or removed.
        expect(prefs.getString('kalkra_career_vault'), storedVault);
        expect(prefs.containsKey('kalkra_career_data'), isFalse);

        // Once storage recovers, the original data is still fully loadable.
        final recovered = await persistence.load(deviceId);
        expect(recovered.playerName, 'RealPlayer');
        expect(recovered.elo, 1500);
      },
    );
  });
}
