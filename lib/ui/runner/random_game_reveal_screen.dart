import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/session.dart';
import '../../theme/app_theme.dart';

/// Wheel-style "random" game reveal.
/// The game is already chosen; animation is deterministic.
class RandomGameRevealScreen extends StatefulWidget {
  final GameType selectedGame;
  final List<GameType> allGames;
  final VoidCallback onComplete;

  const RandomGameRevealScreen({
    super.key,
    required this.selectedGame,
    required this.allGames,
    required this.onComplete,
  });

  @override
  State<RandomGameRevealScreen> createState() => _RandomGameRevealScreenState();
}

class _RandomGameRevealScreenState extends State<RandomGameRevealScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _spinAnim;
  bool _landed = false;

  // The slot list repeats games to create scrolling effect
  late List<GameType> _slotItems;
  static const int _visibleSlots = 5;
  static const double _slotHeight = 64;
  late int _landIndex;

  @override
  void initState() {
    super.initState();

    // Build a long slot list that ends on the selected game
    final games = widget.allGames.isNotEmpty ? widget.allGames : GameType.values.toList();
    final rand = Random();

    // Create ~20 items + ensure last visible one is the selected game
    _slotItems = [];
    for (int i = 0; i < 18; i++) {
      _slotItems.add(games[rand.nextInt(games.length)]);
    }
    _slotItems.add(widget.selectedGame);
    // A couple more after for visual padding
    _slotItems.add(games[rand.nextInt(games.length)]);
    _slotItems.add(games[rand.nextInt(games.length)]);

    _landIndex = 18; // index of selected game

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Animate from 0 (top) to _landIndex position
    _spinAnim = Tween<double>(begin: 0, end: _landIndex.toDouble()).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        HapticFeedback.heavyImpact();
        setState(() => _landed = true);
      }
    });

    // Start spin after brief delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiColors.background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Next Game...',
                style: GoogleFonts.fredoka(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 24),
              // Slot machine area
              SizedBox(
                height: _slotHeight * _visibleSlots,
                child: AnimatedBuilder(
                  animation: _spinAnim,
                  builder: (context, _) {
                    return _buildSlotView();
                  },
                ),
              ),
              const SizedBox(height: 32),
              if (_landed) ...[
                Text(
                  '${gameEmoji(widget.selectedGame)} ${gameDisplayName(widget.selectedGame)}',
                  style: GoogleFonts.fredoka(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: KawaiiColors.deepInk,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gameDescription(widget.selectedGame),
                  style: GoogleFonts.fredoka(
                    fontSize: 15,
                    color: KawaiiColors.deepInk.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: widget.onComplete,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                    decoration: BoxDecoration(
                      color: KawaiiColors.mintGreen,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: KawaiiColors.deepInk, width: 3),
                    ),
                    child: Text(
                      'Start Round!',
                      style: GoogleFonts.fredoka(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotView() {
    final scrollOffset = _spinAnim.value * _slotHeight;
    final centerSlotIndex = 2; // middle of 5 visible slots

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: KawaiiColors.deepInk, width: 3),
          borderRadius: BorderRadius.circular(20),
          color: KawaiiColors.cardWhite,
        ),
        child: Stack(
          children: [
            // Scrolling items
            ...List.generate(_visibleSlots, (vi) {
              final itemOffset = scrollOffset - (centerSlotIndex - vi) * _slotHeight;
              final itemIndex = (itemOffset / _slotHeight).round();

              if (itemIndex < 0 || itemIndex >= _slotItems.length) {
                return const SizedBox.shrink();
              }

              final game = _slotItems[itemIndex];
              final isCenter = vi == centerSlotIndex;
              final opacity = isCenter ? 1.0 : (0.4 - (vi - centerSlotIndex).abs() * 0.1).clamp(0.15, 0.4);

              return Positioned(
                top: vi * _slotHeight,
                left: 0,
                right: 0,
                height: _slotHeight,
                child: Container(
                  decoration: isCenter && _landed
                      ? BoxDecoration(
                          color: KawaiiColors.sunshineYellow.withValues(alpha: 0.3),
                        )
                      : null,
                  child: Center(
                    child: Opacity(
                      opacity: isCenter ? 1.0 : opacity,
                      child: Text(
                        '${gameEmoji(game)} ${gameDisplayName(game)}',
                        style: GoogleFonts.fredoka(
                          fontSize: isCenter ? 22 : 16,
                          fontWeight: isCenter ? FontWeight.w700 : FontWeight.w400,
                          color: KawaiiColors.deepInk,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // Center indicator lines
            Positioned(
              top: centerSlotIndex * _slotHeight - 1,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: KawaiiColors.primaryPink,
              ),
            ),
            Positioned(
              top: (centerSlotIndex + 1) * _slotHeight - 1,
              left: 0,
              right: 0,
              child: Container(
                height: 2,
                color: KawaiiColors.primaryPink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
