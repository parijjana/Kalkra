import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_engine/game_engine.dart';
import 'package:kalkra_app/src/services/career_persistence.dart';

void main() {
  group('CareerPersistence', () {
    const String careerKey = 'kalkra_career_data';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('load() returns default CareerManager if no data exists', () async {
      final prefs = await SharedPreferences.getInstance();
      final persistence = CareerPersistence(prefs);
      
      final career = persistence.load();
      expect(career.elo, 1200);
      expect(career.matchesWon, 0);
    });

    test('save() and load() persists CareerManager data', () async {
      final prefs = await SharedPreferences.getInstance();
      final persistence = CareerPersistence(prefs);
      
      final career = CareerManager(elo: 1500, matchesWon: 10);
      career.recordRoundPerformance(secondsToSubmit: 5.0, proximityToTarget: 0);
      
      await persistence.save(career);
      
      final loadedCareer = persistence.load();
      expect(loadedCareer.elo, 1500);
      expect(loadedCareer.matchesWon, 10);
      expect(loadedCareer.avgSpeedSeconds, 5.0);
    });

    test('clears data correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      final persistence = CareerPersistence(prefs);
      
      await persistence.save(CareerManager(elo: 2000));
      await persistence.clear();
      
      final loaded = persistence.load();
      expect(loaded.elo, 1200); // Default
    });
  });
}
