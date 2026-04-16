import 'package:test/test.dart';
import 'package:game_engine/src/session_manager.dart';

void main() {
  group('SessionManager', () {
    late SessionManager session;

    setUp(() {
      session = SessionManager();
    });

    test('can add players to the session', () {
      session.addPlayer('id1', 'Alice', elo: 1300);
      session.addPlayer('id2', 'Bob');
      expect(session.players.length, 2);
      expect(session.players['id1']?.name, 'Alice');
      expect(session.players['id1']?.currentElo, 1300);
    });

    test('tracks player readiness', () {
      session.addPlayer('id1', 'Alice');
      expect(session.isPlayerReady('id1'), isFalse);
      session.setPlayerReady('id1', true);
      expect(session.isPlayerReady('id1'), isTrue);
    });

    test('allReady is true only when everyone is ready', () {
      session.addPlayer('id1', 'Alice');
      session.addPlayer('id2', 'Bob');
      session.setPlayerReady('id1', true);
      expect(session.allReady, isFalse);
      session.setPlayerReady('id2', true);
      expect(session.allReady, isTrue);
    });

    test('calculates cumulative scores', () {
      session.addPlayer('id1', 'Alice');
      session.recordSubmission('id1', '1+1', 10);
      session.recordSubmission('id1', '2+2', 7);
      expect(session.getPlayerScore('id1'), 17);
      expect(session.players['id1']?.lastExpression, '2+2');
    });

    test('can reset for next round', () {
      session.addPlayer('id1', 'Alice');
      session.setPlayerReady('id1', true);
      session.resetReadiness();
      expect(session.isPlayerReady('id1'), isFalse);
    });

    test('resolves name collisions by appending numbers', () {
      session.addPlayer('id1', 'Alice');
      session.addPlayer('id2', 'Alice');
      session.addPlayer('id3', 'Alice');
      session.addPlayer('id4', 'Bob');
      session.addPlayer('id5', 'Alice');

      expect(session.players['id1']?.name, 'Alice');
      expect(session.players['id2']?.name, 'Alice 2');
      expect(session.players['id3']?.name, 'Alice 3');
      expect(session.players['id4']?.name, 'Bob');
      expect(session.players['id5']?.name, 'Alice 4');
    });
  });
}
