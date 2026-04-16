import 'dart:math';

class EloCalculator {
  static const int kFactor = 32;

  /// Calculates the Elo shift for a player based on their result and the average Elo of opponents.
  static int calculateShift({
    required int playerElo,
    required bool didWin,
    required int opponentElo,
  }) {
    final double expectedScore = 1 / (1 + pow(10, (opponentElo - playerElo) / 400));
    final double actualScore = didWin ? 1.0 : 0.0;
    
    return (kFactor * (actualScore - expectedScore)).round();
  }

  /// Calculates Elo shifts for all players in a session based on the match winner.
  /// This is a simplified multiplayer version: 
  /// The winner is treated as having won against the average Elo of the pool.
  /// Losers are treated as having lost against the winner.
  static Map<String, int> calculateMultiplayerShifts({
    required Map<String, int> playerElos,
    required String winnerId,
  }) {
    final shifts = <String, int>{};
    if (!playerElos.containsKey(winnerId)) return shifts;

    final winnerElo = playerElos[winnerId]!;
    
    // Calculate average Elo of opponents for the winner
    int opponentSum = 0;
    int opponentCount = 0;
    for (final entry in playerElos.entries) {
      if (entry.key != winnerId) {
        opponentSum += entry.value;
        opponentCount++;
      }
    }

    final avgOpponentElo = opponentCount > 0 ? (opponentSum / opponentCount).round() : winnerElo;

    // Winner's shift
    shifts[winnerId] = calculateShift(
      playerElo: winnerElo,
      didWin: true,
      opponentElo: avgOpponentElo,
    );

    // Losers' shifts (treated as loss against winner)
    for (final entry in playerElos.entries) {
      if (entry.key != winnerId) {
        shifts[entry.key] = calculateShift(
          playerElo: entry.value,
          didWin: false,
          opponentElo: winnerElo,
        );
      }
    }

    return shifts;
  }
}
