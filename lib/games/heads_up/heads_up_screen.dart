import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../theme/app_theme.dart';
import '../../engine/round_result.dart';
import '../../engine/content_repository.dart';
import '../../models/session.dart';
import '../../models/player.dart';
import '../../ui/runner/pass_device_screen.dart';
import '../../ui/runner/countdown_screen.dart';
import 'heads_up_logic.dart';

class HeadsUpScreen extends StatefulWidget {
  final Session session;
  final Player activePlayer;
  final void Function(RoundResult result) onComplete;

  const HeadsUpScreen({
    super.key,
    required this.session,
    required this.activePlayer,
    required this.onComplete,
  });

  @override
  State<HeadsUpScreen> createState() => _HeadsUpScreenState();
}

enum _Phase { pass, countdown, play, done }

class _HeadsUpScreenState extends State<HeadsUpScreen> {
  _Phase _phase = _Phase.pass;
  late HeadsUpLogic _logic;
  Timer? _gameTimer;
  int _timeLeft = 0;
  StreamSubscription? _accelSub;
  DateTime? _lastTiltTime;

  // Tilt thresholds: pitch computed from accelerometer
  // +35 degrees in radians = 0.611 rad
  static const double _pitchThresholdDeg = 35.0;
  static const double _pitchThresholdRad = _pitchThresholdDeg * pi / 180.0;
  static const int _debounceMs = 600;
  static const int _stabilizationMs = 120;

  // Stabilization tracking
  DateTime? _tiltStartTime;
  String? _pendingAction; // 'correct' or 'pass'

  @override
  void initState() {
    super.initState();
    final hasKid = widget.session.players.any((p) => p.isKid);
    final words = ContentRepository().getHeadsUpWords(
      kidSafe: hasKid,
      count: 40,
    );
    _logic = HeadsUpLogic(
      activePlayer: widget.activePlayer,
      words: words,
      roundLengthSeconds: widget.session.settings.roundLengthSeconds,
    );
    _timeLeft = _logic.roundLengthSeconds;
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _accelSub?.cancel();
    super.dispose();
  }

  void _startPlay() {
    setState(() => _phase = _Phase.play);
    _startTimer();
    _startTiltDetection();
  }

  void _startTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _endRound();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _startTiltDetection() {
    _accelSub = accelerometerEventStream().listen((event) {
      if (_phase != _Phase.play) return;

      final now = DateTime.now();
      if (_lastTiltTime != null &&
          now.difference(_lastTiltTime!).inMilliseconds < _debounceMs) {
        return;
      }

      // Compute pitch from accelerometer data
      // When phone is held vertically (portrait) facing user:
      //   x ~ 0, y ~ 9.8, z ~ 0
      // Tilt DOWN (forward, correct): y decreases, z becomes more negative
      // Tilt UP (backward, pass): y decreases, z becomes more positive
      // pitch = atan2(-z, y) gives us the forward/backward tilt angle
      final pitch = atan2(-event.z, event.y);

      if (pitch > _pitchThresholdRad) {
        // Tilted DOWN => correct
        if (_pendingAction == 'correct') {
          if (_tiltStartTime != null &&
              now.difference(_tiltStartTime!).inMilliseconds >= _stabilizationMs) {
            _lastTiltTime = now;
            _pendingAction = null;
            _tiltStartTime = null;
            _onCorrect();
          }
        } else {
          _pendingAction = 'correct';
          _tiltStartTime = now;
        }
      } else if (pitch < -_pitchThresholdRad) {
        // Tilted UP => pass
        if (_pendingAction == 'pass') {
          if (_tiltStartTime != null &&
              now.difference(_tiltStartTime!).inMilliseconds >= _stabilizationMs) {
            _lastTiltTime = now;
            _pendingAction = null;
            _tiltStartTime = null;
            _onPass();
          }
        } else {
          _pendingAction = 'pass';
          _tiltStartTime = now;
        }
      } else {
        // Flat - reset pending
        _pendingAction = null;
        _tiltStartTime = null;
      }
    });
  }

  void _onCorrect() {
    if (_phase != _Phase.play || !_logic.hasMoreWords) return;
    if (widget.session.settings.enableHaptics) {
      HapticFeedback.mediumImpact();
    }
    _logic.markCorrect();
    setState(() {});
    if (!_logic.hasMoreWords) _endRound();
  }

  void _onPass() {
    if (_phase != _Phase.play || !_logic.hasMoreWords) return;
    if (widget.session.settings.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    _logic.markPassed();
    setState(() {});
    if (!_logic.hasMoreWords) _endRound();
  }

  void _endRound() {
    _gameTimer?.cancel();
    _accelSub?.cancel();
    setState(() => _phase = _Phase.done);

    final result = _logic.buildResult(
      isPartyMode: widget.session.mode == SessionMode.party,
    );
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) widget.onComplete(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.pass:
        return PassDeviceScreen(
          playerName: widget.activePlayer.name,
          playerColor: widget.activePlayer.avatarColor,
          onReady: () => setState(() => _phase = _Phase.countdown),
        );
      case _Phase.countdown:
        return CountdownScreen(
          enableHaptics: widget.session.settings.enableHaptics,
          onComplete: _startPlay,
        );
      case _Phase.play:
        return _buildPlayScreen();
      case _Phase.done:
        return _buildDoneScreen();
    }
  }

  Widget _buildPlayScreen() {
    return Scaffold(
      backgroundColor: KawaiiColors.skyBlue.withValues(alpha: 0.15),
      body: SafeArea(
        child: Column(
          children: [
            _buildTimerBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '\u2705 ${_logic.correctCount}',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: KawaiiColors.mintGreen,
                    ),
                  ),
                  Text(
                    '${_timeLeft}s',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: KawaiiColors.deepInk,
                    ),
                  ),
                  Text(
                    '\u274C ${_logic.passedCount}',
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: KawaiiColors.primaryPink,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _logic.currentWord,
                    style: GoogleFonts.fredoka(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: KawaiiColors.deepInk,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // Manual buttons (fallback for emulator/testing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _onPass,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: KawaiiColors.primaryPink.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            'Pass',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _onCorrect,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: KawaiiColors.mintGreen.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            'Correct',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tilt DOWN = Correct   Tilt UP = Pass',
              style: GoogleFonts.fredoka(
                fontSize: 12,
                color: KawaiiColors.deepInk.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBar() {
    final progress = _timeLeft / _logic.roundLengthSeconds;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      height: 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: KawaiiColors.deepInk, width: 2),
        color: KawaiiColors.cardWhite,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: progress > 0.3 ? KawaiiColors.skyBlue : KawaiiColors.primaryPink,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoneScreen() {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F389}', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              'Time\'s up!',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: KawaiiColors.deepInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_logic.correctCount} correct',
              style: GoogleFonts.fredoka(
                fontSize: 20,
                color: KawaiiColors.mintGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
