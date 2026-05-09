import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  group('MatchManager: Round Ladder', () {
    test('Progressive mode follows the canonical 8-round sequence', () {
      final match = MatchManager(gameMode: GameMode.progressive, totalRounds: 10);
      match.generateMatch();
      
      // Round 1
      expect(match.currentRound, 1);
      expect(match.currentRoundData?.config.title, equals(RoundConfig.classic.title));
      
      // Round 2
      match.nextRound();
      expect(match.currentRound, 2);
      expect(match.currentRoundData?.config.title, equals(RoundConfig.classic.title));

      // Round 3: Gauntlet
      match.nextRound();
      expect(match.currentRound, 3);
      expect(match.currentRoundData?.config.title, equals(RoundConfig.gauntlet.title));

      // Round 4: Forbidden Number
      match.nextRound();
      expect(match.currentRound, 4);
      expect(match.currentRoundData?.config.title, equals(RoundConfig.forbiddenNumber.title));

      // Round 5: Two Targets
      match.nextRound();
      expect(match.currentRound, 5);
      expect(match.currentRoundData?.config.title, equals(RoundConfig.twoTargets.title));

      // Round 6: Expanding Pool
      match.nextRound();
      expect(match.currentRound, 6);
      expect(match.currentRoundData?.config.title, equals(RoundConfig.expandingPool.title));

      // Round 7: Mandatory Number
      match.nextRound();
      expect(match.currentRound, 7);
      expect(match.currentRoundData?.config.title, equals(RoundConfig.mandatoryNumber.title));
    });
  });
}
