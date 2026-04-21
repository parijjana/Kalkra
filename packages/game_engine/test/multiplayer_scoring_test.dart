import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  group('Multiplayer Winner-Takes-All Scoring', () {
    late RoundManager round;
    late ScoreKeeper scoreKeeper;
    late SubmissionValidator validator;

    setUp(() {
      round = RoundManager();
      scoreKeeper = ScoreKeeper();
      validator = SubmissionValidator();
      // Setup a basic round: target 100, numbers [50, 50, 10, 5]
      round.startRoundWithData(
        numbers: [50, 50, 10, 5],
        target: 100,
      );
    });

    test('Equidistant winners (one above, one below) both get points', () {
      final target = round.target!;
      
      // Player A: 100 - 5 = 95 (Diff 5)
      // Player B: 100 + 5 = 105 (Wait, pool only has [50, 50, 10, 5]. Let's use 50+50+5=105)
      final exprA = "50 + 50 - 5"; // 95
      final exprB = "50 + 50 + 5"; // 105
      
      final valA = validator.validate(exprA, round.numbers).value!.toInt();
      final valB = validator.validate(exprB, round.numbers).value!.toInt();
      
      final diffA = (target - valA).abs();
      final diffB = (target - valB).abs();
      
      expect(diffA, equals(5));
      expect(diffB, equals(5));

      // Simulate the logic used in SpectatorScreen/GameScreen
      int minProximity = [diffA, diffB].reduce((a, b) => a < b ? a : b);
      
      int pointsA = 0;
      if (diffA == minProximity) {
        pointsA = scoreKeeper.calculateScore(target: target, result: valA);
      }

      int pointsB = 0;
      if (diffB == minProximity) {
        pointsB = scoreKeeper.calculateScore(target: target, result: valB);
      }

      expect(pointsA, equals(7)); // Diff 5 gets 7 points
      expect(pointsB, equals(7)); // Diff 5 gets 7 points
    });

    test('Only the closest player gets points (Standard thresholds apply)', () {
      final target = round.target!;
      
      // Player A: 95 (Diff 5)
      // Player B: 90 (Diff 10)
      final exprA = "50 + 50 - 5";
      final exprB = "50 + 50 - 10";
      
      final valA = validator.validate(exprA, round.numbers).value!.toInt();
      final valB = validator.validate(exprB, round.numbers).value!.toInt();
      
      final diffA = (target - valA).abs();
      final diffB = (target - valB).abs();
      
      int minProximity = [diffA, diffB].reduce((a, b) => a < b ? a : b);
      expect(minProximity, equals(5));

      int pointsA = (diffA == minProximity) ? scoreKeeper.calculateScore(target: target, result: valA) : 0;
      int pointsB = (diffB == minProximity) ? scoreKeeper.calculateScore(target: target, result: valB) : 0;

      expect(pointsA, equals(7));
      expect(pointsB, equals(0)); // Player B was further away
    });

    test('If closest player is outside threshold, no one gets points', () {
      final target = round.target!;
      
      // Player A: 50 + 10 = 60 (Diff 40)
      // Standard rule: Diff > 10 gets 0 points.
      final exprA = "50 + 10";
      final valA = validator.validate(exprA, round.numbers).value!.toInt();
      final diffA = (target - valA).abs();
      
      int minProximity = diffA;
      
      int pointsA = (diffA == minProximity) ? scoreKeeper.calculateScore(target: target, result: valA) : 0;
      
      expect(pointsA, equals(0)); 
    });

    test('Multiple players with exact match all get full points', () {
      final target = round.target!;
      final exprA = "50 + 50";
      final exprB = "50 + 50";
      
      final valA = validator.validate(exprA, round.numbers).value!.toInt();
      final valB = validator.validate(exprB, round.numbers).value!.toInt();
      
      final diffA = (target - valA).abs();
      final diffB = (target - valB).abs();
      
      int minProximity = 0;
      
      int pointsA = (diffA == minProximity) ? scoreKeeper.calculateScore(target: target, result: valA) : 0;
      int pointsB = (diffB == minProximity) ? scoreKeeper.calculateScore(target: target, result: valB) : 0;

      expect(pointsA, equals(10));
      expect(pointsB, equals(10));
    });
  });
}
