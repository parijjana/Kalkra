import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_providers.dart';

class HostedSessionParticipant {
  final String name;
  final String deviceId;
  final int elo;
  final int score;

  HostedSessionParticipant({
    required this.name,
    required this.deviceId,
    required this.elo,
    required this.score,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'deviceId': deviceId,
    'elo': elo,
    'score': score,
  };
  factory HostedSessionParticipant.fromJson(Map<String, dynamic> json) =>
      HostedSessionParticipant(
        name: json['name'],
        deviceId: json['deviceId'],
        elo: json['elo'],
        score: json['score'],
      );
}

class HostedSessionRecord {
  final DateTime date;
  final List<HostedSessionParticipant> participants;
  final String difficulty;
  final int rounds;

  HostedSessionRecord({
    required this.date,
    required this.participants,
    required this.difficulty,
    required this.rounds,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'participants': participants.map((p) => p.toJson()).toList(),
    'difficulty': difficulty,
    'rounds': rounds,
  };

  factory HostedSessionRecord.fromJson(Map<String, dynamic> json) =>
      HostedSessionRecord(
        date: DateTime.parse(json['date']),
        participants: (json['participants'] as List)
            .map((p) => HostedSessionParticipant.fromJson(p))
            .toList(),
        difficulty: json['difficulty'],
        rounds: json['rounds'],
      );
}

class HostedSessionManager extends Notifier<List<HostedSessionRecord>> {
  static const String _historyKey = 'kalkra_hosted_history';
  static const String _banListKey = 'kalkra_banned_devices';

  late SharedPreferences _prefs;

  @override
  List<HostedSessionRecord> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return _loadHistory();
  }

  List<HostedSessionRecord> _loadHistory() {
    final data = _prefs.getStringList(_historyKey) ?? [];
    return data
        .map((s) => HostedSessionRecord.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  Future<void> recordSession(HostedSessionRecord record) async {
    final current = _loadHistory().reversed.toList();
    current.add(record);
    if (current.length > 50) current.removeAt(0); // Pragmatic limit
    await _prefs.setStringList(
      _historyKey,
      current.map((s) => jsonEncode(s.toJson())).toList(),
    );
    state = current.reversed.toList();
  }

  List<String> getBannedDeviceIds() {
    return _prefs.getStringList(_banListKey) ?? [];
  }

  Future<void> banDevice(String deviceId) async {
    final banned = getBannedDeviceIds().toSet();
    banned.add(deviceId);
    await _prefs.setStringList(_banListKey, banned.toList());
  }

  Future<void> unbanDevice(String deviceId) async {
    final banned = getBannedDeviceIds().toSet();
    banned.remove(deviceId);
    await _prefs.setStringList(_banListKey, banned.toList());
  }
}

final hostedSessionProvider =
    NotifierProvider<HostedSessionManager, List<HostedSessionRecord>>(
      HostedSessionManager.new,
    );
