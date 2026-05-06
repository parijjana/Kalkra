import 'package:test/test.dart';
import 'package:game_engine/game_engine.dart';

void main() {
  group('SessionManager: Team Logic', () {
    late SessionManager session;

    setUp(() {
      session = SessionManager();
    });

    test('addPlayer should not create duplicate Guest names when updating stats', () {
      session.addPlayer('id1', 'Guest');
      expect(session.players['id1']?.name, 'Guest');
      
      // Update same player
      session.addPlayer('id1', 'Guest', elo: 1300);
      expect(session.players['id1']?.name, 'Guest'); // Should NOT become Guest 2
      expect(session.players['id1']?.currentElo, 1300);
      expect(session.players.length, 1);
    });

    test('addPlayer should ensure unique names for different IDs', () {
      session.addPlayer('id1', 'Guest');
      session.addPlayer('id2', 'Guest');
      expect(session.players['id1']?.name, 'Guest');
      expect(session.players['id2']?.name, 'Guest 2');
    });

    test('assignTeam should correctly update team assignments', () {
      session.addPlayer('p1', 'Player 1');
      session.assignTeam('p1', 1);
      expect(session.players['p1']?.teamId, 1);
      
      session.assignTeam('p1', 0); // Move back to unassigned
      expect(session.players['p1']?.teamId, 0);
    });

    test('allAssignedReady should only care about players in teams', () {
      session.addPlayer('p1', 'Team Player');
      session.addPlayer('p2', 'Idle Player');
      
      session.assignTeam('p1', 1);
      session.assignTeam('p2', 0); // Unassigned
      
      session.setPlayerReady('p1', false);
      expect(session.allAssignedReady, false);
      
      session.setPlayerReady('p1', true);
      // Even if p2 is not ready, p1 is the only one assigned
      expect(session.allAssignedReady, true);
    });

    test('allAssignedSubmitted should be true only when everyone in a team has a non-null expression', () {
      session.addPlayer('p1', 'Player 1');
      session.addPlayer('p2', 'Player 2');
      session.addPlayer('p3', 'Player 3');
      
      session.assignTeam('p1', 1);
      session.assignTeam('p2', 2);
      session.assignTeam('p3', 0); // Unassigned
      
      expect(session.allAssignedSubmitted, isFalse);
      
      session.recordSubmission('p1', '1+1', 0);
      expect(session.allAssignedSubmitted, isFalse);
      
      session.recordSubmission('p2', '2+2', 0);
      // p1 and p2 submitted, p3 is unassigned, so it should be true
      expect(session.allAssignedSubmitted, isTrue);
    });
  });
}
