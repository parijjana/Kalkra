import 'package:test/test.dart';
import 'package:game_engine/src/game_settings.dart';
import 'package:game_engine/src/number_generator.dart';

void main() {
  group('GameSettings', () {
    test('default values are correct', () {
      final settings = GameSettings();
      expect(settings.playerName, 'Player');
      expect(settings.difficulty, Difficulty.medium);
      expect(settings.soundEnabled, isTrue);
      expect(settings.musicEnabled, isTrue);
      expect(settings.darkMode, isFalse);
    });

    test('can update values via copyWith', () {
      final settings = GameSettings();
      final updated = settings.copyWith(
        playerName: 'Alice',
        difficulty: Difficulty.hard,
        soundEnabled: false,
        darkMode: true,
      );
      expect(updated.playerName, 'Alice');
      expect(updated.difficulty, Difficulty.hard);
      expect(updated.soundEnabled, isFalse);
      expect(updated.musicEnabled, isTrue); // Unchanged
      expect(updated.darkMode, isTrue);
    });

    test('to/from json conversion', () {
      final settings = GameSettings(playerName: 'Bob', difficulty: Difficulty.easy, soundEnabled: false);
      final json = settings.toJson();
      final fromJson = GameSettings.fromJson(json);
      
      expect(fromJson.playerName, 'Bob');
      expect(fromJson.difficulty, Difficulty.easy);
      expect(fromJson.soundEnabled, isFalse);
      expect(fromJson.musicEnabled, isTrue);
    });
  });
}
