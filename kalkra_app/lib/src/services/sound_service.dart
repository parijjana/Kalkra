import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import '../providers/providers.dart';

/// A service to manage sound effects and music in the game.
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  SoundService._internal();

  final _logger = Logger('SoundService');
  final AudioPlayer _fxPlayer = AudioPlayer();
  final AudioPlayer _musicPlayer = AudioPlayer();
  
  WidgetRef? _ref;

  void updateRef(WidgetRef ref) {
    _ref = ref;
  }

  bool get _isSoundEnabled {
    if (_ref == null) return true;
    final career = _ref!.read(careerProvider).value;
    return career?.soundEnabled ?? true;
  }

  bool get _isMusicEnabled {
    if (_ref == null) return true;
    final career = _ref!.read(careerProvider).value;
    return career?.musicEnabled ?? true;
  }

  /// Initialize the sound service.
  Future<void> init() async {
    _logger.info('Initializing SoundService');
  }

  /// Play a sound effect from the assets.
  Future<void> playSfx(String assetName) async {
    if (!_isSoundEnabled) return;
    try {
      await _fxPlayer.stop();
      await _fxPlayer.play(AssetSource('audio/$assetName'));
    } catch (e) {
      _logger.warning('Failed to play SFX: $assetName', e);
    }
  }

  /// Play background music.
  Future<void> playMusic(String assetName) async {
    if (!_isMusicEnabled) return;
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('audio/$assetName'));
    } catch (e) {
      _logger.warning('Failed to play music: $assetName', e);
    }
  }

  /// Stop background music.
  Future<void> stopMusic() async {
    await _musicPlayer.stop();
  }

  /// Toggle background music based on state.
  Future<void> syncMusicState(String assetName) async {
    if (_isMusicEnabled) {
      if (_musicPlayer.state != PlayerState.playing) {
        await playMusic(assetName);
      }
    } else {
      await stopMusic();
    }
  }

  /// Play a generic tap/click sound.
  Future<void> playTap() => playSfx('tap.mp3');

  /// Play a success/correct sound.
  Future<void> playSuccess() => playSfx('success.mp3');

  /// Play a failure/error sound.
  Future<void> playError() => playSfx('error.mp3');

  /// Play a level start/round start sound.
  Future<void> playStart() => playSfx('start.mp3');

  /// Play a countdown tick.
  Future<void> playTick() => playSfx('tick.mp3');

  void dispose() {
    _fxPlayer.dispose();
    _musicPlayer.dispose();
  }
}
