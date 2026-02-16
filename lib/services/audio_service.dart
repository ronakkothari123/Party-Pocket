import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// Tracks what audio mode was active before an app lifecycle pause.
enum _AudioMode { none, main, win }

/// Singleton audio service managing background music and win jingles.
class AudioService {
  static final AudioService _instance = AudioService._();
  factory AudioService() => _instance;
  AudioService._();

  final AudioPlayer _bgPlayer = AudioPlayer();
  final AudioPlayer _winPlayer = AudioPlayer();
  final Random _rand = Random();

  static const int _mainTrackCount = 8;
  static const int _winTrackCount = 2;

  int _lastMainTrack = -1;
  bool _enabled = true;
  double _volume = 0.35;
  bool _mainLoopActive = false;
  bool _initialized = false;
  bool _userHasInteracted = false;

  bool get enabled => _enabled;
  double get volume => _volume;

  /// Call once at app start.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('[AudioService] session config error: $e');
    }

    await _bgPlayer.setVolume(_volume);
    await _winPlayer.setVolume(0.5);

    // When bg track completes, play next
    _bgPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && _mainLoopActive && _enabled) {
        _playNextMainTrack();
      }
    });

    // When win track completes, do nothing (don't auto-resume main)
    _winPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        // Win done - stay silent until Home or Play Again
      }
    });
  }

  /// Register a user gesture (tap). Called on first button press.
  void registerUserGesture() {
    _userHasInteracted = true;
  }

  /// Attempt to start main loop. Safe to call multiple times.
  Future<void> startMainLoopIfNeeded() async {
    if (!_userHasInteracted || !_enabled || _mainLoopActive) return;
    await startMainMusic();
  }

  void setEnabled(bool value) {
    _enabled = value;
    if (!_enabled) {
      stopMainMusic();
      _winPlayer.stop();
    } else if (_userHasInteracted) {
      startMainLoopIfNeeded();
    }
  }

  Future<void> setVolume(double v) async {
    _volume = v.clamp(0.0, 1.0);
    await _bgPlayer.setVolume(_volume);
    await _winPlayer.setVolume((_volume * 1.4).clamp(0.0, 1.0));
  }

  int _pickMainTrack() {
    if (_mainTrackCount <= 1) return 1;
    int pick;
    do {
      pick = _rand.nextInt(_mainTrackCount) + 1;
    } while (pick == _lastMainTrack);
    return pick;
  }

  Future<void> _playNextMainTrack() async {
    if (!_enabled) return;
    final track = _pickMainTrack();
    _lastMainTrack = track;
    try {
      debugPrint('[AudioService] playing main_$track');
      await _bgPlayer.setAsset('assets/music/main_$track.mp3');
      await _bgPlayer.setVolume(_volume);
      await _bgPlayer.play();
    } catch (e) {
      debugPrint('[AudioService] error playing main_$track: $e');
    }
  }

  /// Start the background music rotation.
  Future<void> startMainMusic() async {
    if (_mainLoopActive) return;
    _mainLoopActive = true;
    await _playNextMainTrack();
  }

  /// Resume main music (e.g. after returning from win screen or Home).
  Future<void> resumeMainMusic() async {
    if (!_enabled) return;
    await _winPlayer.stop();
    _mainLoopActive = true;
    await _playNextMainTrack();
  }

  /// Stop main music.
  Future<void> stopMainMusic() async {
    _mainLoopActive = false;
    await _bgPlayer.stop();
  }

  /// Play a random win track once, stopping main music first.
  Future<void> playWinMusic() async {
    if (!_enabled) return;
    _mainLoopActive = false;
    await _bgPlayer.stop();

    final winTrack = _rand.nextInt(_winTrackCount) + 1;
    try {
      debugPrint('[AudioService] playing win_$winTrack');
      await _winPlayer.setAsset('assets/music/win_$winTrack.mp3');
      await _winPlayer.setVolume((_volume * 1.4).clamp(0.0, 1.0));
      await _winPlayer.play();
    } catch (e) {
      debugPrint('[AudioService] error playing win_$winTrack: $e');
    }
  }

  /// Stop win music.
  Future<void> stopWinMusic() async {
    await _winPlayer.stop();
  }

  // ── App lifecycle support ──────────────────────────────────

  _AudioMode _modeBeforePause = _AudioMode.none;

  /// Call when the app is paused / backgrounded.
  Future<void> handleAppPaused() async {
    if (_winPlayer.playing) {
      _modeBeforePause = _AudioMode.win;
      await _winPlayer.pause();
    } else if (_bgPlayer.playing) {
      _modeBeforePause = _AudioMode.main;
      await _bgPlayer.pause();
    } else {
      _modeBeforePause = _AudioMode.none;
    }
    debugPrint('[AudioService] paused (was: $_modeBeforePause)');
  }

  /// Call when the app resumes to foreground.
  Future<void> handleAppResumed() async {
    if (!_enabled) return;
    switch (_modeBeforePause) {
      case _AudioMode.win:
        await _winPlayer.play();
        break;
      case _AudioMode.main:
        await _bgPlayer.play();
        break;
      case _AudioMode.none:
        break;
    }
    debugPrint('[AudioService] resumed (restoring: $_modeBeforePause)');
    _modeBeforePause = _AudioMode.none;
  }

  void dispose() {
    _bgPlayer.dispose();
    _winPlayer.dispose();
  }
}
