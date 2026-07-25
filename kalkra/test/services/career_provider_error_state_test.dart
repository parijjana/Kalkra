import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:game_engine/game_engine.dart';
import 'package:kalkra/src/providers/providers.dart';
import 'package:kalkra/src/services/career_persistence.dart';
import 'package:kalkra/src/services/persistence_security.dart';

/// A [CareerPersistence] whose [load] always fails with the kind of
/// transient platform failure that `CareerPersistence.load()` rethrows
/// (e.g. keychain unavailable), and which records every [save] call so a
/// test can prove that nothing was ever written.
class _FailingLoadPersistence extends CareerPersistence {
  _FailingLoadPersistence(super.prefs);

  int saveCalls = 0;

  @override
  Future<CareerManager> load(String deviceId) {
    throw PlatformException(
      code: 'errSecMissingEntitlement',
      message: '-34018',
    );
  }

  @override
  Future<bool> save(CareerManager career, String deviceId) {
    saveCalls++;
    return super.save(career, deviceId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CareerNotifier error state', () {
    const deviceId = 'test-device-id';

    test(
      'mutators no-op while careerProvider is in AsyncError, so a failed '
      'load can never be clobbered by a later save',
      () async {
        SharedPreferences.setMockInitialValues({});
        FlutterSecureStorage.setMockInitialValues({});
        PersistenceSecurity.storage = const FlutterSecureStorage();
        final prefs = await SharedPreferences.getInstance();

        // A real, healthy save exists on disk (written while storage worked).
        final real = CareerManager(playerName: 'RealPlayer', elo: 1500);
        await CareerPersistence(prefs).save(real, deviceId);
        final storedVault = prefs.getString('kalkra_career_vault');
        expect(storedVault, isNotNull);

        final failing = _FailingLoadPersistence(prefs);
        final container = ProviderContainer(
          // Riverpod 3 retries failed providers by default; disable so the
          // provider stays deterministically in AsyncError for this test.
          retry: (retryCount, error) => null,
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            deviceIdProvider.overrideWith((ref) => Future.value(deviceId)),
            careerPersistenceProvider.overrideWithValue(failing),
          ],
        );
        addTearDown(container.dispose);

        // The failing load puts the provider into an error state.
        await expectLater(
          container.read(careerProvider.future),
          throwsA(isA<PlatformException>()),
        );
        expect(
          container.read(careerProvider),
          isA<AsyncError<CareerManager>>(),
        );

        // Mutations while in the error state must be no-ops: with no loaded
        // manager there is nothing safe to mutate, and saving would
        // overwrite the real on-disk career with a default one.
        final notifier = container.read(careerProvider.notifier);
        await notifier.setSoundEnabled(false);
        await notifier.setPlayerName('Clobberer');
        await notifier.applyEloShift(50, 'Rival');

        expect(failing.saveCalls, 0);
        // The on-disk save is byte-for-byte untouched.
        expect(prefs.getString('kalkra_career_vault'), storedVault);
        // And the provider is still reporting the error, not fake data.
        expect(
          container.read(careerProvider),
          isA<AsyncError<CareerManager>>(),
        );
      },
    );
  });
}
