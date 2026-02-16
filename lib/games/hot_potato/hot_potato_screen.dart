import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';
import '../../engine/round_result.dart';
import '../../engine/content_repository.dart';
import '../../models/session.dart';
import '../../models/player.dart';
import '../../ui/runner/countdown_screen.dart';
import 'hot_potato_logic.dart';

class HotPotatoScreen extends StatefulWidget {
  final Session session;
  final Player startingPlayer;
  final void Function(RoundResult result) onComplete;

  const HotPotatoScreen({
    super.key,
    required this.session,
    required this.startingPlayer,
    required this.onComplete,
  });

  @override
  State<HotPotatoScreen> createState() => _HotPotatoScreenState();
}

enum _HotPotatoPhase { instructions, countdown, play, done }

class _HotPotatoScreenState extends State<HotPotatoScreen> {
  _HotPotatoPhase _phase = _HotPotatoPhase.instructions;
  late HotPotatoLogic _logic;
  Timer? _mainTimer;
  Timer? _tickTimer;
  int _elapsedMs = 0;
  int _tickIntervalMs = 1000;
  bool _exploded = false;

  // Tooltip state for circle diagram
  int? _tooltipIndex;

  @override
  void initState() {
    super.initState();
    final category = ContentRepository().getHotPotatoCategory();
    _logic = HotPotatoLogic(
      players: widget.session.players,
      startingPlayer: widget.startingPlayer,
      category: category,
    );
  }

  @override
  void dispose() {
    _mainTimer?.cancel();
    _tickTimer?.cancel();
    super.dispose();
  }

  void _startPlay() {
    setState(() => _phase = _HotPotatoPhase.play);

    _mainTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _elapsedMs += 100;
      if (_elapsedMs >= _logic.totalDurationMs) {
        t.cancel();
        _tickTimer?.cancel();
        _onExplode();
      }
      setState(() {});
    });

    _startTick();
  }

  void _startTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(Duration(milliseconds: _tickIntervalMs), (_) {
      if (widget.session.settings.enableHaptics) {
        HapticFeedback.selectionClick();
      }

      final progress = _elapsedMs / _logic.totalDurationMs;
      if (progress > 0.8) {
        _updateTickInterval(150);
      } else if (progress > 0.6) {
        _updateTickInterval(300);
      } else if (progress > 0.4) {
        _updateTickInterval(500);
      } else if (progress > 0.2) {
        _updateTickInterval(700);
      }
    });
  }

  void _updateTickInterval(int ms) {
    if (ms != _tickIntervalMs) {
      _tickIntervalMs = ms;
      _startTick();
    }
  }

  void _onPass() {
    _logic.passToNext();
    setState(() {});
  }

  void _onRepeated() {
    _logic.setLoserAsCurrent();
    _mainTimer?.cancel();
    _tickTimer?.cancel();
    _finishRound();
  }

  void _onExplode() {
    _exploded = true;
    _logic.setLoserAsCurrent();
    if (widget.session.settings.enableHaptics) {
      HapticFeedback.heavyImpact();
    }
    _finishRound();
  }

  void _finishRound() {
    setState(() => _phase = _HotPotatoPhase.done);
    final result = _logic.buildResult(
      isPartyMode: widget.session.mode == SessionMode.party,
    );
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) widget.onComplete(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _HotPotatoPhase.instructions:
        return _buildInstructionsScreen();
      case _HotPotatoPhase.countdown:
        return CountdownScreen(
          enableHaptics: widget.session.settings.enableHaptics,
          onComplete: _startPlay,
        );
      case _HotPotatoPhase.play:
        return _buildPlayScreen();
      case _HotPotatoPhase.done:
        return _buildDoneScreen();
    }
  }

  Widget _buildInstructionsScreen() {
    final players = widget.session.players;

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('\u{1F954}', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 16),
                Text(
                  'Sit in a Circle',
                  style: GoogleFonts.fredoka(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.deepInk,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sit in your real-life order.\nPass the phone to the next person clockwise.',
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Interactive circle diagram with player initials
                SizedBox(
                  height: 180,
                  width: 180,
                  child: Stack(
                    children: [
                      // Arrow arc (clockwise)
                      CustomPaint(
                        size: const Size(180, 180),
                        painter: _CircleArrowPainter(
                          playerCount: players.length.clamp(3, 8),
                        ),
                      ),
                      // Player nodes
                      ..._buildPlayerNodes(players),
                      // Tooltip bubble
                      if (_tooltipIndex != null)
                        _buildTooltipBubble(players),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap a circle to see the name',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () => setState(() => _phase = _HotPotatoPhase.countdown),
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: KawaiiColors.mintGreen,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: KawaiiColors.deepInk, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        'We\'re Ready!',
                        style: GoogleFonts.fredoka(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlayerNodes(List<Player> players) {
    final count = players.length.clamp(3, 8);
    final centerX = 90.0;
    final centerY = 90.0;
    final radius = 66.0;
    final nodeRadius = 20.0;

    final nodes = <Widget>[];
    for (int i = 0; i < count && i < players.length; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      final x = centerX + radius * math.cos(angle) - nodeRadius;
      final y = centerY + radius * math.sin(angle) - nodeRadius;
      final player = players[i];
      final initial = player.name.isNotEmpty ? player.name[0].toUpperCase() : '?';

      nodes.add(
        Positioned(
          left: x,
          top: y,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _tooltipIndex = _tooltipIndex == i ? null : i;
              });
            },
            child: Container(
              width: nodeRadius * 2,
              height: nodeRadius * 2,
              decoration: BoxDecoration(
                color: player.avatarColor,
                shape: BoxShape.circle,
                border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.fredoka(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.cardWhite,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return nodes;
  }

  Widget _buildTooltipBubble(List<Player> players) {
    final count = players.length.clamp(3, 8);
    final idx = _tooltipIndex!;
    if (idx >= players.length) return const SizedBox.shrink();

    final angle = -math.pi / 2 + (2 * math.pi * idx / count);
    final centerX = 90.0;
    final centerY = 90.0;
    final radius = 66.0;
    final nodeX = centerX + radius * math.cos(angle);
    final nodeY = centerY + radius * math.sin(angle);

    // Position tooltip above the node
    final tooltipX = nodeX;
    final tooltipY = nodeY - 38;

    return Positioned(
      left: (tooltipX - 40).clamp(0.0, 100.0),
      top: tooltipY.clamp(0.0, 140.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: KawaiiColors.cardWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KawaiiColors.deepInk, width: 2),
          boxShadow: [
            BoxShadow(
              color: KawaiiColors.deepInk.withValues(alpha: 0.08),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Text(
          players[idx].name,
          style: GoogleFonts.fredoka(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: KawaiiColors.deepInk,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayScreen() {
    final progress = (_elapsedMs / _logic.totalDurationMs).clamp(0.0, 1.0);
    final urgencyColor = progress > 0.7
        ? KawaiiColors.primaryPink
        : progress > 0.4
            ? KawaiiColors.sunshineYellow
            : KawaiiColors.mintGreen;

    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
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
                    widthFactor: (1.0 - progress),
                    child: Container(
                      decoration: BoxDecoration(
                        color: urgencyColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _logic.category,
                style: GoogleFonts.fredoka(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: KawaiiColors.deepInk,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Say something from this category!',
                style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: _logic.currentHolder.avatarColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KawaiiColors.deepInk, width: 2.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('\u{1F954}', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      _logic.currentHolder.name,
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _onPass,
                child: Container(
                  width: double.infinity,
                  height: 72,
                  decoration: BoxDecoration(
                    color: KawaiiColors.skyBlue,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: KawaiiColors.deepInk, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      'OK - Pass!',
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: KawaiiColors.deepInk,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _onRepeated,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: KawaiiColors.primaryPink.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: KawaiiColors.deepInk, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      'Repeated! (Out)',
                      style: GoogleFonts.fredoka(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KawaiiColors.primaryPink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
            Text(
              _exploded ? '\u{1F4A5}' : '\u{274C}',
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            Text(
              _exploded ? 'BOOM!' : 'Repeated!',
              style: GoogleFonts.fredoka(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: KawaiiColors.primaryPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Paints a dashed circle arc with a clockwise arrow
class _CircleArrowPainter extends CustomPainter {
  final int playerCount;
  _CircleArrowPainter({required this.playerCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 24;

    final paint = Paint()
      ..color = const Color(0xFF2B2B2B).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw dashed circle
    const dashCount = 36;
    for (int i = 0; i < dashCount; i++) {
      final startAngle = (2 * math.pi * i / dashCount);
      final sweepAngle = (2 * math.pi / dashCount) * 0.6;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
