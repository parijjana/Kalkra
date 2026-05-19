import 'package:test/test.dart';
import 'package:game_engine/src/career_manager.dart';
import 'package:game_engine/src/elo_calculator.dart';

void main() {
  group('CareerManager', () {
    late CareerManager career;

    setUp(() {
      career = CareerManager();
    });

    test('initializes with default values', () {
      expect(career.playerName, 'Guest');
      expect(career.elo, 1200);
      expect(career.matchesWon, 0);
      expect(career.avgSpeedSeconds, 0.0);
      expect(career.avgAccuracy, 0.0);
      expect(career.currentStreak, 0);
      expect(career.bestStreak, 0);
    });

    test('serialization works', () {
      final updated = career.copyWith(
        playerName: 'Tester',
        elo: 1300,
        avgSpeedSeconds: 5.0,
      );
      
      final json = updated.toJson();
      final fromJson = CareerManager.fromJson(json);
      
      expect(fromJson.playerName, 'Tester');
      expect(fromJson.elo, 1300);
      expect(fromJson.avgSpeedSeconds, 5.0);
    });
  });

  group('EloCalculator', () {
    test('calculates shift correctly', () {
      final shift = EloCalculator.calculateShift(
        playerElo: 1200,
        didWin: true,
        opponentElo: 1200,
      );
      expect(shift, equals(16)); // (1.0 - 0.5) * 32
    });

    test('Elo shift depends on opponent skill', () {
      final gainAgainstPro = EloCalculator.calculateShift(
        playerElo: 1200,
        didWin: true,
        opponentElo: 2000,
      );
      final gainAgainstNoob = EloCalculator.calculateShift(
        playerElo: 1200,
        didWin: true,
        opponentElo: 800,
      );

      expect(gainAgainstPro, greaterThan(gainAgainstNoob));
    });

    test('Multiplayer shifts are distributed', () {
      final elos = {'me': 1200, 'alice': 1200, 'bob': 1200};
      final shifts = EloCalculator.calculateMultiplayerShifts(
        playerElos: elos,
        winnerId: 'me',
      );

      expect(shifts['me'], greaterThan(0));
      expect(shifts['alice'], lessThan(0));
      expect(shifts['bob'], lessThan(0));
    });
  });
}
