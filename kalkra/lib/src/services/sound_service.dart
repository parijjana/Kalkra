import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

/// A service to manage sound effects and background music with cross-fading, playlist cycling, and lifecycle support.
class SoundService with WidgetsBindingObserver {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;

  SoundService._internal() {
    _initAudioContext();
    
    _bgmPlayer.setReleaseMode(ReleaseMode.release); // release so we can detect completion and cycle
    _bgmPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    
    _bgmPlayer.onPlayerComplete.listen((_) => _onBgmComplete());

    // Initialize SFX pool
    for (int i = 0; i < _sfxPoolSize; i++) {
      final p = AudioPlayer();
      p.setPlayerMode(PlayerMode.lowLatency);
      _sfxPool.add(p);
    }
    
    WidgetsBinding.instance.addObserver(this);
  }

  void _initAudioContext() {
    AudioPlayer.global.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        stayAwake: false,
        contentType: AndroidContentType.music,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: const {
          AVAudioSessionOptions.mixWithOthers,
          AVAudioSessionOptions.duckOthers,
        },
      ),
    ));
  }

  final _log = Logger('SoundService');
  final AudioPlayer _bgmPlayer = AudioPlayer();

  static const int _sfxPoolSize = 10;
  final List<AudioPlayer> _sfxPool = [];
  int _nextSfxIndex = 0;

  bool _isSoundEnabled = true;
  bool _isMusicEnabled = true;
  double _sfxVolume = 0.8;
  double _bgmVolume = 0.4;
  
  List<String> _playlist = [];
  int _currentTrackIndex = -1;
  
  Timer? _fadeTimer;
  bool _isAppInForeground = true;

  void setSoundEnabled(bool enabled) => _isSoundEnabled = enabled;

  void setMusicEnabled(bool enabled) {
    _isMusicEnabled = enabled;
    if (!enabled) {
      stopBgm(immediate: true);
    } else {
      if (_bgmPlayer.state == PlayerState.paused) {
        _bgmPlayer.resume();
      } else if (_bgmPlayer.state != PlayerState.playing && !_isFading) {
        _playNextInPlaylist();
      }
    }
  }

  void updatePlaylist(List<String> tracks) {
    _playlist = tracks;
    if (_isMusicEnabled && 
        _bgmPlayer.state != PlayerState.playing && 
        _bgmPlayer.state != PlayerState.paused &&
        _playlist.isNotEmpty) {
      _playNextInPlaylist();
    }
  }

  void setSfxVolume(double volume) {
    _sfxVolume = volume;
    for (final p in _sfxPool) {
      p.setVolume(_sfxVolume);
    }
  }

  void setBgmVolume(double volume) {
    _bgmVolume = volume;
    if (!_isFading) _bgmPlayer.setVolume(_bgmVolume);
  }

  bool get _isFading => _fadeTimer != null;

  Future<void> playSfx(String fileName) async {
    if (!_isSoundEnabled || !_isAppInForeground) return;
    try {
      final player = _sfxPool[_nextSfxIndex];
      _nextSfxIndex = (_nextSfxIndex + 1) % _sfxPoolSize;
      player.setVolume(_sfxVolume);
      player.play(AssetSource('audio/$fileName'), mode: PlayerMode.lowLatency);
    } catch (e) {
      _log.warning('Could not play sfx $fileName: $e');
    }
  }

  /// Ensures music is playing if enabled. Use this on screen builds.
  void ensureMusicPlaying() {
    if (!_isMusicEnabled || !_isAppInForeground || _playlist.isEmpty) return;
    if (_bgmPlayer.state == PlayerState.paused) {
      _bgmPlayer.resume();
    } else if (_bgmPlayer.state != PlayerState.playing && !_isFading) {
      _playNextInPlaylist();
    }
  }

  void _onBgmComplete() {
    if (!_isAppInForeground) return;
    if (_isMusicEnabled) {
      _playNextInPlaylist();
    }
  }

  void _playNextInPlaylist() {
    if (!_isAppInForeground || _playlist.isEmpty) return;
    
    _currentTrackIndex++;
    if (_currentTrackIndex >= _playlist.length) {
      _currentTrackIndex = 0;
      _playlist.shuffle(); // Shuffle for variety
    }

    _startCrossFade(_playlist[_currentTrackIndex]);
  }

  void _startCrossFade(String nextFile) async {
    if (!_isAppInForeground) return;
    _fadeTimer?.cancel();
    
    const steps = 15; // Slightly faster fade
    const interval = Duration(milliseconds: 100); 
    double startVol = _bgmPlayer.volume;
    double stepSize = startVol / steps;

    int count = 0;
    _fadeTimer = Timer.periodic(interval, (timer) async {
      count++;
      if (!_isAppInForeground) {
        timer.cancel();
        _fadeTimer = null;
        _bgmPlayer.stop();
        return;
      }
      double newVol = (startVol - (stepSize * count)).clamp(0.0, 1.0);
      await _bgmPlayer.setVolume(newVol);

      if (count >= steps) {
        timer.cancel();
        _fadeTimer = null;
        
        await _bgmPlayer.stop();
        await _bgmPlayer.setVolume(0);
        try {
          if (_isAppInForeground && _isMusicEnabled) {
            await _bgmPlayer.play(AssetSource('audio/bgm/$nextFile'));
            _fadeIn();
          }
        } catch (e) {
          _log.warning('Fade in failed for $nextFile: $e');
          // If a file fails, try the next one after a short delay
          Future.delayed(const Duration(seconds: 2), () => _playNextInPlaylist());
        }
      }
    });
  }

  void _fadeIn() {
    _fadeTimer?.cancel();
    if (!_isAppInForeground) return;
    const steps = 15;
    const interval = Duration(milliseconds: 100);
    double targetVol = _bgmVolume;
    double stepSize = targetVol / steps;

    int count = 0;
    _fadeTimer = Timer.periodic(interval, (timer) async {
      count++;
      if (!_isAppInForeground) {
        timer.cancel();
        _fadeTimer = null;
        _bgmPlayer.stop();
        return;
      }
      double newVol = (stepSize * count).clamp(0.0, targetVol);
      await _bgmPlayer.setVolume(newVol);

      if (count >= steps) {
        timer.cancel();
        _fadeTimer = null;
        await _bgmPlayer.setVolume(targetVol);
      }
    });
  }

  Future<void> stopBgm({bool immediate = false}) async {
    if (immediate) {
      _fadeTimer?.cancel();
      _fadeTimer = null;
      await _bgmPlayer.stop();
    } else {
      await _bgmPlayer.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive || state == AppLifecycleState.detached) {
      _isAppInForeground = false;
      _bgmPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      _isAppInForeground = true;
      if (_isMusicEnabled) {
        final playerState = _bgmPlayer.state;
        if (playerState == PlayerState.paused) {
          _bgmPlayer.resume();
        } else if (playerState == PlayerState.stopped || playerState == PlayerState.completed) {
          _playNextInPlaylist();
        }
      }
    }
  }

  Future<void> playTap() => playSfx('tap.ogg');
  Future<void> playSuccess() => playSfx('success.ogg');
  Future<void> playError() => playSfx('error.ogg');
  Future<void> playStart() => playSfx('start.ogg');
  Future<void> playTick() => playSfx('tick.ogg');

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeTimer?.cancel();
    _bgmPlayer.dispose();
    for (final p in _sfxPool) {
      p.dispose();
    }
  }
}
