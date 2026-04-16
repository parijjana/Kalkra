import 'package:test/test.dart';
import 'package:game_engine/src/career_manager.dart';

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

    test('can update player name', () {
      career.setPlayerName('MathWiz');
      expect(career.playerName, 'MathWiz');
    });

    test('updates metrics after a round', () {
      career.recordRoundPerformance(
        secondsToSubmit: 10.0,
        proximityToTarget: 2,
      );
      expect(career.avgSpeedSeconds, 10.0);
      expect(career.avgAccuracy, 2.0);
      expect(career.currentStreak, 0);

      career.recordRoundPerformance(
        secondsToSubmit: 20.0,
        proximityToTarget: 0, // Exact match
      );
      // Avg speed: (10 + 20) / 2 = 15.0
      expect(career.avgSpeedSeconds, 15.0);
      // Avg accuracy: (2 + 0) / 2 = 1.0
      expect(career.avgAccuracy, 1.0);
      expect(career.currentStreak, 1);
      expect(career.bestStreak, 1);
    });

    test('tracks streaks correctly', () {
      career.recordRoundPerformance(secondsToSubmit: 5, proximityToTarget: 0);
      career.recordRoundPerformance(secondsToSubmit: 5, proximityToTarget: 0);
      expect(career.currentStreak, 2);
      expect(career.bestStreak, 2);

      career.recordRoundPerformance(secondsToSubmit: 5, proximityToTarget: 1); // Miss
      expect(career.currentStreak, 0);
      expect(career.bestStreak, 2);

      career.recordRoundPerformance(secondsToSubmit: 5, proximityToTarget: 0);
      expect(career.currentStreak, 1);
      expect(career.bestStreak, 2);
    });

    test('calculates Elo shift correctly (simple win)', () {
      final initialElo = career.elo;
      // Win against an opponent with same Elo
      career.recordMatchResult(
        didWin: true,
        opponentElo: 1200,
        opponentName: 'Alice',
      );
      
      expect(career.elo, greaterThan(initialElo));
      expect(career.matchesWon, 1);
      expect(career.rivals.length, 1);
      expect(career.rivals.first.name, 'Alice');
    });

    test('Elo shift depends on opponent skill', () {
      career.recordMatchResult(didWin: true, opponentElo: 2000, opponentName: 'Pro');
      final gainAgainstPro = career.elo - 1200;

      final career2 = CareerManager();
      career2.recordMatchResult(didWin: true, opponentElo: 800, opponentName: 'Noob');
      final gainAgainstNoob = career2.elo - 1200;

      expect(gainAgainstPro, greaterThan(gainAgainstNoob));
    });

    test('serialization works', () {
      career.setPlayerName('Tester');
      career.recordRoundPerformance(secondsToSubmit: 5, proximityToTarget: 0);
      career.recordMatchResult(didWin: true, opponentElo: 1200, opponentName: 'Bob');
      
      final json = career.toJson();
      final fromJson = CareerManager.fromJson(json);
      
      expect(fromJson.playerName, 'Tester');
      expect(fromJson.elo, career.elo);
      expect(fromJson.avgSpeedSeconds, 5.0);
      expect(fromJson.currentStreak, 1);
      expect(fromJson.rivals.first.name, 'Bob');
    });
  });
}
