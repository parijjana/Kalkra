import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_engine/game_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'playtest_service.g.dart';

class PlaytestResult {
  final String playerName;
  final String mode;
  final String difficulty;
  final int score;
  final int totalRounds;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  PlaytestResult({
    required this.playerName,
    required this.mode,
    required this.difficulty,
    required this.score,
    required this.totalRounds,
    required this.timestamp,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'player_name': playerName,
    'mode': mode,
    'difficulty': difficulty,
    'score': score,
    'total_rounds': totalRounds,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

@Riverpod(keepAlive: true)
class PlaytestService extends _$PlaytestService {
  static const String _nameKey = 'playtest_player_name';
  late SharedPreferences _prefs;
  bool _initialized = false;

  @override
  FutureOr<void> build() async {
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  String? get playerName => _prefs.getString(_nameKey);

  Future<void> setPlayerName(String name) async {
    await _prefs.setString(_nameKey, name);
  }

  Future<bool> submitResult(MatchManager match, int score) async {
    if (!_initialized) return false;

    final name = playerName ?? 'Anonymous';

    final result = PlaytestResult(
      playerName: name,
      mode: match.gameMode.name,
      difficulty: match.initialDifficulty.name,
      score: score,
      totalRounds: match.totalRounds,
      timestamp: DateTime.now(),
      metadata: {
        'platform': kIsWeb ? 'web' : 'native',
        'userAgent': kIsWeb ? 'browser' : 'app',
      },
    );

    try {
      // In web playtest, we assume the API is relative to the origin
      final baseUrl = kIsWeb ? '' : 'http://localhost:8000';
      final response = await http.post(
        Uri.parse('$baseUrl/api/results'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(result.toJson()),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Failed to submit playtest result: $e');
      return false;
    }
  }
}
