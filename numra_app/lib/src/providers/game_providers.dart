import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transport_interface/transport_interface.dart';
import 'package:transport_lan/transport_lan.dart';
import 'package:game_engine/game_engine.dart';

/// Provider for the transport layer. 
/// Defaults to NullTransport for solo play.
final transportProvider = StateProvider<IGameTransport>((ref) {
  return NullTransport();
});

/// Provider for the current game settings.
final settingsProvider = Provider<ValueNotifier<GameSettings>>((ref) {
  return ValueNotifier(GameSettings());
});

/// Provider for the active match.
final matchProvider = Provider<ValueNotifier<MatchManager?>>((ref) {
  return ValueNotifier(null);
});

/// Provider for the session manager.
final sessionProvider = Provider<SessionManager>((ref) {
  return SessionManager();
});

/// Provider for the career manager (persistence).
final careerProvider = Provider<ValueNotifier<CareerManager>>((ref) {
  return ValueNotifier(CareerManager());
});

/// Provider for the round manager (logic for a single round).
final roundProvider = Provider<RoundManager>((ref) {
  return RoundManager();
});

/// Stream provider for transport events.
final gameEventStreamProvider = StreamProvider<GameEvent>((ref) {
  final transport = ref.watch(transportProvider);
  return transport.eventStream;
});
